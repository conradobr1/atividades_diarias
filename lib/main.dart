import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart' as http;

void main() => runApp(MaterialApp(
      title: 'Atividades diárias',
      debugShowCheckedModeBanner: false,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xff176b55),
        scaffoldBackgroundColor: const Color(0xfff2f6f4),
      ),
      home: const PaginaAtividades(),
    ));

String dois(int n) => n.toString().padLeft(2, '0');
String ano(DateTime data) => data.year.toString().padLeft(4, '0');
String dataBr(DateTime data) =>
    '${dois(data.day)}/${dois(data.month)}/${ano(data)}';

DateTime? lerData(String texto) {
  final partes = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$').firstMatch(texto.trim());
  if (partes == null) return null;
  final dia = int.parse(partes[1]!);
  final mes = int.parse(partes[2]!);
  final ano = int.parse(partes[3]!);
  final data = DateTime(ano, mes, dia);
  if (ano == 0 || data.year != ano || data.month != mes || data.day != dia) {
    return null;
  }
  return data;
}

class Atividade {
  Atividade.fromJson(Map<String, dynamic> json)
      : dia = DateTime.parse(json['dia'] as String),
        descricao = json['atividade'] as String;

  final DateTime dia;
  final String descricao;
}

class AtividadesApi {
  final cliente = http.Client();
  final uri = Uri.parse(
      '${const String.fromEnvironment('API_BASE_URL', defaultValue: kIsWeb ? '' : 'http://10.0.2.2:8080')}/api/atividades');

  Future<List<Atividade>> listar(DateTime mes) async {
    final url =
        uri.replace(queryParameters: {'mes': '${ano(mes)}-${dois(mes.month)}'});
    final resposta =
        await cliente.get(url).timeout(const Duration(seconds: 10));
    if (resposta.statusCode != 200) throw Exception('Erro na consulta');
    final registros =
        jsonDecode(utf8.decode(resposta.bodyBytes)) as List<dynamic>;
    return registros
        .map((item) => Atividade.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> salvar(DateTime dia, String descricao) async {
    final resposta = await cliente
        .post(
          uri,
          headers: {'Content-Type': 'application/json; charset=utf-8'},
          body: jsonEncode({
            'dia': '${ano(dia)}-${dois(dia.month)}-${dois(dia.day)}',
            'atividade': descricao,
          }),
        )
        .timeout(const Duration(seconds: 10));
    if (resposta.statusCode != 201) throw Exception('Erro no cadastro');
  }
}

class PaginaAtividades extends StatefulWidget {
  const PaginaAtividades({super.key});

  @override
  State<PaginaAtividades> createState() => _PaginaAtividadesState();
}

class _PaginaAtividadesState extends State<PaginaAtividades> {
  final _formulario = GlobalKey<FormState>();
  final _dia = TextEditingController();
  final _descricao = TextEditingController();
  final _api = AtividadesApi();
  late DateTime _mes;
  late Future<List<Atividade>> _atividades;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    final hoje = DateTime.now();
    _dia.text = dataBr(hoje);
    _mes = DateTime(hoje.year, hoje.month);
    _atividades = _api.listar(_mes);
  }

  @override
  void dispose() {
    _dia.dispose();
    _descricao.dispose();
    _api.cliente.close();
    super.dispose();
  }

  void _selecionarMes(DateTime data) {
    setState(() {
      _mes = DateTime(data.year, data.month);
      _atividades = _api.listar(_mes);
    });
  }

  Future<void> _salvar() async {
    if (_salvando || !_formulario.currentState!.validate()) return;
    final data = lerData(_dia.text)!;
    setState(() => _salvando = true);
    try {
      await _api.salvar(data, _descricao.text.trim());
      if (!mounted) return;
      _descricao.clear();
      _selecionarMes(data);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Atividade cadastrada.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Não foi possível salvar. Verifique o servidor.')),
      );
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final anterior = DateTime(_mes.year, _mes.month - 1);
    final seguinte = DateTime(_mes.year, _mes.month + 1);
    final tema = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Atividades diárias'),
        backgroundColor: tema.scaffoldBackgroundColor,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formulario,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Nova atividade',
                            style: tema.textTheme.titleLarge),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _dia,
                          enabled: !_salvando,
                          keyboardType: TextInputType.datetime,
                          decoration: const InputDecoration(
                            labelText: 'Data',
                            helperText: 'DD/MM/AAAA',
                            border: OutlineInputBorder(),
                          ),
                          validator: (valor) => lerData(valor ?? '') == null
                              ? 'Digite uma data válida no formato DD/MM/AAAA.'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descricao,
                          enabled: !_salvando,
                          minLines: 2,
                          maxLines: 5,
                          maxLength: 500,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration(
                            labelText: 'Atividade realizada',
                            border: OutlineInputBorder(),
                          ),
                          validator: (valor) => (valor ?? '').trim().isEmpty
                              ? 'Digite a atividade realizada.'
                              : null,
                        ),
                        FilledButton.icon(
                          onPressed: _salvando ? null : _salvar,
                          icon: const Icon(Icons.add),
                          label: Text(
                              _salvando ? 'Salvando…' : 'Salvar atividade'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  IconButton(
                    tooltip: 'Mês anterior',
                    onPressed: anterior.year > 0
                        ? () => _selecionarMes(anterior)
                        : null,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Expanded(
                    child: Text(
                      MaterialLocalizations.of(context).formatMonthYear(_mes),
                      style: tema.textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Próximo mês',
                    onPressed: seguinte.year <= 9999
                        ? () => _selecionarMes(seguinte)
                        : null,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              FutureBuilder<List<Atividade>>(
                future: _atividades,
                builder: (context, resultado) {
                  if (resultado.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (resultado.hasError) {
                    return Column(
                      children: [
                        const Text('Não foi possível carregar as atividades.'),
                        TextButton(
                          onPressed: () => _selecionarMes(_mes),
                          child: const Text('Tentar novamente'),
                        ),
                      ],
                    );
                  }
                  final registros = resultado.requireData;
                  if (registros.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Nenhuma atividade cadastrada neste mês.',
                          textAlign: TextAlign.center),
                    );
                  }
                  return Column(
                    children: [
                      for (final item in registros)
                        Card(
                          elevation: 0,
                          child: ListTile(
                            leading: const Icon(Icons.event_note_outlined),
                            title: Text(item.descricao),
                            subtitle: Text(dataBr(item.dia)),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
