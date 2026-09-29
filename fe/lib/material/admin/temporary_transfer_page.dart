import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:fe/services/api_service.dart';
import 'package:fe/services/auth_session.dart';

class TemporaryTransferPage extends StatefulWidget {
  const TemporaryTransferPage({super.key});
  @override
  State<TemporaryTransferPage> createState() => _TemporaryTransferPageState();
}

class _TemporaryTransferPageState extends State<TemporaryTransferPage> {
  final _path = TextEditingController();
  String _destination = 'drive';
  bool _busy = false;
  double? _progress;
  String? _error;
  List<dynamic> _jobs = [];
  String get _base => ApiService().baseUrl.replaceAll(RegExp(r'/+$'), '');
  Map<String,String> get _headers {
    final token = AuthSession.instance.accessToken;
    if (token == null || token.isEmpty) throw StateError('Accedi nuovamente all’area admin.');
    return {'Authorization':'Bearer $token', 'Content-Type':'application/json'};
  }
  @override
  void initState() { super.initState(); _load(); }
  @override
  void dispose() { _path.dispose(); super.dispose(); }

  Future<dynamic> _api(String path, [Map<String,dynamic>? data]) async {
    final uri = Uri.parse('$_base/admin/temporary-transfers$path');
    final response = await (data == null ? http.get(uri, headers:_headers) : http.post(uri, headers:_headers, body:jsonEncode(data))).timeout(const Duration(seconds:40));
    dynamic body;
    try { body=jsonDecode(utf8.decode(response.bodyBytes)); } catch (_) { body=null; }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = body is Map && body['detail'] is String ? body['detail'] as String : 'Servizio temporaneamente non disponibile.';
      throw StateError(message);
    }
    return body;
  }
  String _message(Object e) => e is StateError ? e.message.toString() : 'Operazione non completata. Controlla la connessione e riprova.';
  Future<void> _load() async {
    try {
      final rows=await _api('');
      if(mounted) setState(() { _jobs=rows as List<dynamic>; _error=null; });
    } catch(e) { if(mounted) setState(() => _error=_message(e)); }
  }
  Future<void> _action(String id,String action) async {
    setState(() => _busy=true);
    try { await _api('/$id/$action',{}); await _load(); }
    catch(e) { if(mounted) setState(() => _error=_message(e)); }
    finally { if(mounted) setState(() => _busy=false); }
  }
  String _mime(String name) {
    final ext=name.split('.').last.toLowerCase();
    return const {'pdf':'application/pdf','txt':'text/plain','csv':'text/csv','zip':'application/zip','png':'image/png','jpg':'image/jpeg','jpeg':'image/jpeg','docx':'application/vnd.openxmlformats-officedocument.wordprocessingml.document','pptx':'application/vnd.openxmlformats-officedocument.presentationml.presentation'}[ext] ?? 'application/octet-stream';
  }
  Future<void> _upload() async {
    setState(() { _busy=true; _error=null; _progress=null; });
    try {
      final selection=await FilePicker.pickFiles(withData:true,allowMultiple:false);
      if(selection==null) return;
      final file=selection.files.single, bytes=file.bytes;
      if(bytes==null || file.size==0 || file.size>50*1024*1024) throw StateError('Scegli un file non vuoto fino a 50 MB.');
      final segments=_path.text.split('/').where((s)=>s.trim().isNotEmpty).map((s)=>s.trim()).toList();
      final mime=_mime(file.name);
      final job=await _api('/prepare',{'filename':file.name,'size':bytes.length,'sha256':sha256.convert(bytes).toString(),'mime_type':mime,'destination':_destination,'path_segments':segments}) as Map;
      final authorization=await http.post(Uri.parse('$_base/api/blob-transfer'),headers:_headers,body:jsonEncode({'job_id':job['id']})).timeout(const Duration(seconds:40));
      if(authorization.statusCode!=200) throw StateError('Caricamento non autorizzato. Controlla il deploy del backend.');
      final url=Uri.parse((jsonDecode(authorization.body) as Map)['upload_url'] as String);
      if(url.scheme!='https') throw StateError('Destinazione temporanea non valida.');
      if(mounted) setState(() => _progress=0);
      final response=await http.put(url,headers:{'Content-Type':mime,'x-vercel-blob-access':'private'},body:bytes).timeout(const Duration(minutes:10));
      if(response.statusCode<200||response.statusCode>=300) throw StateError('Caricamento incompleto. Annulla questo tentativo e ricarica il file.');
      if(mounted) setState(() => _progress=1);
      await _api('/${job['id']}/ready',{});
      await _load();
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('File caricato. La copia partirà al prossimo avvio del servizio.')));
    } catch(e) { if(mounted) setState(() => _error=_message(e)); }
    finally { if(mounted) setState(() { _busy=false; _progress=null; }); }
  }
  static const _states={'uploading':'Caricamento da confermare','pending':'In attesa della copia','running':'Copia in corso','failed':'Copia non confermata','completed':'Copia verificata','cancelled':'Annullato','expired':'Scaduto'};
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar:AppBar(title:const Text('Carica su Drive o MEGA'),actions:[IconButton(onPressed:_busy?null:_load,icon:const Icon(Icons.refresh),tooltip:'Aggiorna')]),
    body:ListView(padding:const EdgeInsets.all(16),children:[
      const Text('Il file resta temporaneamente su StudentLab. Dopo la verifica della copia viene eliminato dal deposito temporaneo. I tentativi incompleti scadono dopo 7 giorni.'),
      const SizedBox(height:16),
      SegmentedButton<String>(segments:const [ButtonSegment(value:'drive',label:Text('Google Drive')),ButtonSegment(value:'mega',label:Text('MEGA'))],selected:{_destination},onSelectionChanged:_busy?null:(v)=>setState(()=>_destination=v.first)),
      const SizedBox(height:12),
      TextField(controller:_path,enabled:!_busy,decoration:InputDecoration(labelText:'Sottocartelle (facoltativo)',hintText:'Materia/Argomento',helperText:_destination=='mega'?'Percorso dentro /StudentLab del tuo account MEGA':'Percorso dentro la cartella Drive di StudentLab')),
      const SizedBox(height:12),
      FilledButton.icon(onPressed:_busy?null:_upload,icon:const Icon(Icons.upload_file),label:const Text('Scegli e carica file · massimo 50 MB')),
      if(_busy) Padding(padding:const EdgeInsets.symmetric(vertical:12),child:LinearProgressIndicator(value:_progress==1?1:null)),
      if(_error!=null) Padding(padding:const EdgeInsets.symmetric(vertical:12),child:Text(_error!,style:TextStyle(color:Theme.of(context).colorScheme.error))),
      const SizedBox(height:16),const Text('Trasferimenti',style:TextStyle(fontWeight:FontWeight.bold,fontSize:18)),
      for(final raw in _jobs) _jobCard(raw as Map),
    ]),
  );
  Widget _jobCard(Map j) {
    final state=j['state'] as String;
    return Card(child:Padding(padding:const EdgeInsets.all(12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text(j['filename'] as String,style:const TextStyle(fontWeight:FontWeight.bold)),
      Text('${j['destination']=='mega'?'MEGA':'Drive'} · ${_states[state]??state}'),
      Text((j['path_segments'] as List).join('/')),
      if(j['error']!=null) Text(j['error'] as String),
      if(state=='completed') Text(j['cleaned']==true?'Copia temporanea eliminata':'Pulizia temporanea in attesa'),
      Wrap(spacing:8,children:[
        if(state=='failed'&&j['cleaned']!=true) TextButton(onPressed:_busy?null:()=>_action(j['id'] as String,'retry'),child:const Text('Riprova')),
        if(state=='uploading') TextButton(onPressed:_busy?null:()=>_action(j['id'] as String,'ready'),child:const Text('Verifica caricamento')),
        if(['uploading','pending','failed'].contains(state)) TextButton(onPressed:_busy?null:()=>_action(j['id'] as String,'cancel'),child:const Text('Annulla')),
      ]),
    ])));
  }
}
