import 'package:flutter/material.dart';

import '../../theme/nightTheme.dart';

class GroupChatLayer extends StatefulWidget {
  final String groupId;
  final String groupName;
  final String subjectName;

  const GroupChatLayer({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.subjectName,
  });

  @override
  State<GroupChatLayer> createState() => _GroupChatLayerState();
}

class _GroupChatLayerState extends State<GroupChatLayer> {
  final TextEditingController _controller =
      TextEditingController();

  final ScrollController _scrollController =
      ScrollController();

  // ===========================================================================
  // UTENTE CORRENTE
  // ===========================================================================

  final String currentUserName = 'Franz';

  // ===========================================================================
  // MESSAGGI TEMPORANEI
  // ===========================================================================

  final List<_ChatMessage> messages = [
    _ChatMessage(
      senderId: '1',
      senderName: 'Marco',
      text: 'Ragazzi, qualcuno ha capito i puntatori?',
      isMine: false,
    ),

    _ChatMessage(
      senderId: '2',
      senderName: 'Francesca',
      text: 'Sì, sto studiando proprio quell\'argomento.',
      isMine: false,
    ),

    _ChatMessage(
      senderId: 'me',
      senderName: 'Franz',
      text: 'Io sto ripassando gli esempi del professore.',
      isMine: true,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkElegance,

      appBar: AppBar(
        backgroundColor: AppColors.brandNightBlue,
        foregroundColor: AppColors.pureWhite,
        elevation: 0,

        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.groupName,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),

            Text(
              widget.subjectName,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.pureWhite.withOpacity(0.60),
              ),
            ),
          ],
        ),
      ),

      body: Column(
        children: [
          Expanded(
            child: _buildMessages(),
          ),

          _buildInput(),
        ],
      ),
    );
  }

  // ===========================================================================
  // MESSAGGI
  // ===========================================================================

  Widget _buildMessages() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];

        return _buildMessage(message);
      },
    );
  }

  Widget _buildMessage(_ChatMessage message) {
    if (message.isMine) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          constraints: const BoxConstraints(
            maxWidth: 320,
          ),

          margin: const EdgeInsets.only(
            bottom: 12,
            left: 50,
          ),

          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 11,
          ),

          decoration: BoxDecoration(
            color: AppColors.socialBlue,
            borderRadius: BorderRadius.circular(16),
          ),

          child: Text(
            message.text,
            style: const TextStyle(
              color: AppColors.pureWhite,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,

      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 320,
        ),

        margin: const EdgeInsets.only(
          bottom: 12,
          right: 50,
        ),

        padding: const EdgeInsets.all(12),

        decoration: BoxDecoration(
          color: AppColors.charcoalGrey,
          borderRadius: BorderRadius.circular(16),
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                _openUserCard(message.senderId);
              },

              child: Text(
                message.senderName,
                style: const TextStyle(
                  color: AppColors.skyBlue,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 5),

            Text(
              message.text,
              style: const TextStyle(
                color: AppColors.pureWhite,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // INPUT
  // ===========================================================================

  Widget _buildInput() {
    return SafeArea(
      top: false,

      child: Container(
        padding: const EdgeInsets.fromLTRB(
          12,
          8,
          12,
          8,
        ),

        decoration: BoxDecoration(
          color: AppColors.brandNightBlue,

          border: Border(
            top: BorderSide(
              color: AppColors.pureWhite.withOpacity(0.08),
            ),
          ),
        ),

        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,

                style: const TextStyle(
                  color: AppColors.pureWhite,
                ),

                decoration: InputDecoration(
                  hintText: 'Scrivi un messaggio...',
                  hintStyle: TextStyle(
                    color: AppColors.pureWhite.withOpacity(0.45),
                  ),

                  filled: true,
                  fillColor: AppColors.charcoalGrey,

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),

                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),

                onSubmitted: (_) {
                  _sendMessage();
                },
              ),
            ),

            const SizedBox(width: 8),

            IconButton(
              tooltip: 'Invia',
              onPressed: _sendMessage,

              icon: const Icon(
                Icons.send_rounded,
                color: AppColors.skyBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // INVIO
  // ===========================================================================

  void _sendMessage() {
    final text = _controller.text.trim();

    if (text.isEmpty) {
      return;
    }

    setState(() {
      messages.add(
        _ChatMessage(
          senderId: 'me',
          senderName: currentUserName,
          text: text,
          isMine: true,
        ),
      );
    });

    _controller.clear();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ===========================================================================
  // CARD UTENTE
  // ===========================================================================

  void _openUserCard(String userId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Apertura profilo utente $userId',
        ),
      ),
    );

    // In seguito:
    //
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (_) => SocialUserProfilePage(
    //       userId: userId,
    //     ),
    //   ),
    // );
  }
}

// =============================================================================
// MODELLO TEMPORANEO MESSAGGIO
// =============================================================================

class _ChatMessage {
  final String senderId;
  final String senderName;
  final String text;
  final bool isMine;

  const _ChatMessage({
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.isMine,
  });
}