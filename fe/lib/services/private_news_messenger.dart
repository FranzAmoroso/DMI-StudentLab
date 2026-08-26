import '../models/device_public_key.dart';
import '../social/news/models/news_board.dart';
import 'auth_session.dart';
import 'device_key_service.dart';
import 'news_api_service.dart';
import 'private_news_crypto.dart';

class PrivateConversationMessage {
  final NewsPrivateMessage raw;
  final String text;
  final bool isReadable;

  const PrivateConversationMessage({
    required this.raw,
    required this.text,
    required this.isReadable,
  });

  String get id => raw.id;

  int get senderId => raw.senderId;

  int get recipientId => raw.recipientId;

  DateTime get createdAt => raw.createdAt;

  bool get canDelete => raw.canDelete;

  bool isMine(int viewerId) => raw.senderId == viewerId;

  int counterpartId(int viewerId) => raw.counterpartId(viewerId);

  String counterpartName(int viewerId) => raw.counterpartName(viewerId);
}

class PrivateNewsMessenger {
  PrivateNewsMessenger({
    NewsApiService? newsApi,
    DeviceKeyService? deviceKeys,
    PrivateNewsCryptoService? crypto,
    AuthSession? session,
    this.requireComplianceWrap = true,
  })  : _newsApi = newsApi ?? NewsApiService(),
        _deviceKeys = deviceKeys ?? DeviceKeyService(),
        _crypto = crypto ?? PrivateNewsCryptoService(),
        _session = session ?? AuthSession.instance;

  final NewsApiService _newsApi;
  final DeviceKeyService _deviceKeys;
  final PrivateNewsCryptoService _crypto;
  final AuthSession _session;

  final bool requireComplianceWrap;

  DeviceKeyMaterial? _material;
  bool _published = false;

  Future<PrivateConversationMessage> send({
    required int recipientId,
    required String text,
  }) async {
    final int senderId = _requireUserId();

    if (recipientId == senderId) {
      throw ArgumentError('Non puoi inviare un messaggio a te stesso.');
    }

    final DeviceKeyMaterial material = await _ensurePublishedMaterial();

    final List<PrivateNewsRecipient> recipients = <PrivateNewsRecipient>[
      PrivateNewsRecipient.device(
        userId: senderId,
        deviceId: material.deviceId,
        publicKeyBase64: material.publicKey,
      ),
    ];

    for (final DevicePublicKey key in await _deviceKeys.ownDevices().then(
      (DevicePublicKeyListResult result) => result.activeItems,
    )) {
      if (key.deviceId == material.deviceId) {
        continue;
      }

      recipients.add(
        PrivateNewsRecipient.device(
          userId: senderId,
          deviceId: key.deviceId,
          publicKeyBase64: key.publicKey,
        ),
      );
    }

    final List<DevicePublicKey> recipientDevices =
        await _deviceKeys.recipientDevices(recipientId);

    if (recipientDevices.isEmpty) {
      throw StateError(
        'Il destinatario non ha ancora un dispositivo registrato: '
        'non è possibile inviare un messaggio cifrato.',
      );
    }

    for (final DevicePublicKey key in recipientDevices) {
      recipients.add(
        PrivateNewsRecipient.device(
          userId: recipientId,
          deviceId: key.deviceId,
          publicKeyBase64: key.publicKey,
        ),
      );
    }

    final ComplianceKey compliance = await _deviceKeys.complianceKey();

    if (compliance.isUsable) {
      recipients.add(
        PrivateNewsRecipient.compliance(
          keyId: compliance.keyId,
          publicKeyBase64: compliance.publicKey,
        ),
      );
    } else if (requireComplianceWrap) {
      throw StateError(
        'Chiave di conformità non disponibile: l’invio è bloccato perché '
        'il messaggio non potrebbe essere reso leggibile su richiesta '
        'dell’autorità.',
      );
    }

    final EncryptedPrivateNews encrypted = await _crypto.encrypt(
      plaintext: text,
      senderId: senderId,
      senderDeviceId: material.deviceId,
      recipients: recipients,
    );

    final NewsPrivateMessage stored = await _newsApi.sendPrivateNews(
      recipientId: recipientId,
      ciphertext: encrypted.ciphertext,
      algo: encrypted.algo,
      metadata: encrypted.metadata,
    );

    return PrivateConversationMessage(
      raw: stored,
      text: text.trim(),
      isReadable: true,
    );
  }

  Future<List<PrivateConversationMessage>> conversation({
    required int otherUserId,
    int limit = 30,
    int offset = 0,
  }) async {
    final NewsPrivateMessageListResult result =
        await _newsApi.getPrivateConversation(
      otherUserId: otherUserId,
      limit: limit,
      offset: offset,
    );

    return _decryptAll(result.items);
  }

  Future<List<PrivateConversationMessage>> inbox({
    int limit = 30,
    int offset = 0,
  }) async {
    final NewsPrivateMessageListResult result = await _newsApi.getPrivateInbox(
      limit: limit,
      offset: offset,
    );

    return _decryptAll(result.items);
  }

  Future<void> delete({
    required int otherUserId,
    required PrivateConversationMessage message,
  }) async {
    await _newsApi.deletePrivateNews(
      otherUserId: otherUserId,
      newsId: message.id,
      writeToken: message.raw.writeToken,
    );
  }

  Future<String> discloseContentKey(
    PrivateConversationMessage message,
  ) async {
    final DeviceKeyMaterial material = await _ensureMaterial();

    return _crypto.discloseContentKey(
      metadata: message.raw.metadata,
      keyPair: material.keyPair,
      wrapTarget: _wrapTarget(
        material,
      ),
    );
  }

  Future<List<PrivateConversationMessage>> _decryptAll(
    List<NewsPrivateMessage> messages,
  ) async {
    if (messages.isEmpty) {
      return <PrivateConversationMessage>[];
    }

    final DeviceKeyMaterial material = await _ensureMaterial();
    final String wrapTarget = _wrapTarget(material);

    final List<PrivateConversationMessage> decrypted =
        <PrivateConversationMessage>[];

    for (final NewsPrivateMessage message in messages) {
      decrypted.add(
        await _decryptOne(
          message: message,
          material: material,
          wrapTarget: wrapTarget,
        ),
      );
    }

    return decrypted;
  }

  Future<PrivateConversationMessage> _decryptOne({
    required NewsPrivateMessage message,
    required DeviceKeyMaterial material,
    required String wrapTarget,
  }) async {
    if (!_crypto.canDecrypt(
      metadata: message.metadata,
      wrapTarget: wrapTarget,
    )) {
      return PrivateConversationMessage(
        raw: message,
        text: '',
        isReadable: false,
      );
    }

    try {
      final String text = await _crypto.decrypt(
        ciphertext: message.ciphertext,
        metadata: message.metadata,
        keyPair: material.keyPair,
        wrapTarget: wrapTarget,
      );

      return PrivateConversationMessage(
        raw: message,
        text: text,
        isReadable: true,
      );
    } on PrivateNewsCryptoException {
      return PrivateConversationMessage(
        raw: message,
        text: '',
        isReadable: false,
      );
    }
  }

  String _wrapTarget(DeviceKeyMaterial material) {
    return '${_requireUserId()}:${material.deviceId}';
  }

  Future<DeviceKeyMaterial> _ensureMaterial() async {
    final DeviceKeyMaterial? cached = _material;

    if (cached != null) {
      return cached;
    }

    final DeviceKeyMaterial material = await _deviceKeys.ensureDeviceKeys();

    _material = material;

    return material;
  }

  Future<DeviceKeyMaterial> _ensurePublishedMaterial() async {
    final DeviceKeyMaterial material = await _ensureMaterial();

    if (!_published) {
      await _deviceKeys.publishDeviceKey();

      _published = true;
    }

    return material;
  }

  int _requireUserId() {
    final int? userId = _session.currentUserId;

    if (!_session.isAuthenticated || userId == null) {
      throw StateError('Utente non autenticato.');
    }

    return userId;
  }
}
