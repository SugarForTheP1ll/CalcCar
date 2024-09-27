import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'database/database_manager.dart';
import 'login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  runApp(const AppGastos());
}

class AppGastos extends StatelessWidget {
  const AppGastos({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const LoginScreen(),
    );
  }
}

class TelaGastos extends StatefulWidget {
  final String username;

  const TelaGastos({super.key, required this.username});

  @override
  _TelaGastosState createState() => _TelaGastosState();
}

class _TelaGastosState extends State<TelaGastos> {
  final DatabaseManager _dbManager = DatabaseManager();
  bool _valorOculto = false;
  double _totalGastos = 0.0;
  final List<Map<String, dynamic>> _gastos = [];
  String? _fotoPerfil;
  final ImagePicker _picker = ImagePicker();
  double _custoPorKm = 0.0; 

  final List<String> _tiposDeGasto = [
    'Gasolina',
    'Pneus',
    'Manutenção',
    'Troca de Óleo',
    'Lavagem',
  ];

  String? _tipoSelecionado;

  @override
  void initState() {
    super.initState();
    _carregarFotoPerfil();
  }

  void _carregarFotoPerfil() async {
    final foto = await _dbManager.loadProfilePhoto(widget.username);
    if (foto != null) {
      setState(() {
        _fotoPerfil = foto;
      });
    }
  }

  Future<void> _escolherFotoPerfil() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      await _dbManager.saveProfilePhoto(widget.username, base64Image);

      setState(() {
        _fotoPerfil = base64Image;
      });
    }
  }

  Widget _buildProfilePicture() {
    return InkWell(
      onTap: _escolherFotoPerfil, 
      child: CircleAvatar(
        radius: 40,
        backgroundImage: _fotoPerfil != null
            ? MemoryImage(base64Decode(_fotoPerfil!))
            : null, // Exibe a imagem carregada
        child: _fotoPerfil == null
            ? const Icon(Icons.add_a_photo, size: 40) 
            : null, 
      ),
    );
  }

  void _atualizarTotalGastos() {
    setState(() {
      _totalGastos = _gastos.fold(0.0, (soma, item) => soma + item['valor']);
    });
  }

  void _adicionarNovoGasto(String titulo, double valor) {
    setState(() {
      _gastos.add({'titulo': titulo, 'valor': valor});
      _atualizarTotalGastos();
    });
  }

  void _abrirDialogoAdicionarGasto() {
    String novoValor = '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Adicionar Novo Gasto'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Tipo de Gasto'),
                value: _tipoSelecionado,
                onChanged: (String? newValue) {
                  setState(() {
                    _tipoSelecionado = newValue!;
                  });
                },
                items: _tiposDeGasto.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Valor'),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  novoValor = value;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_tipoSelecionado != null && novoValor.isNotEmpty) {
                  try {
                    final valor = double.parse(novoValor);
                    _adicionarNovoGasto(_tipoSelecionado!, valor);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Valor inválido.')),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Por favor, selecione o tipo de gasto.')),
                  );
                }
                Navigator.of(context).pop();
              },
              child: const Text('Adicionar'),
            ),
          ],
        );
      },
    );
  }

  void _abrirDialogoCalcularKmRodados() {
    String kmPorLitro = '';
    String kmRodados = '';
    String precoGasolina = '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Calcular Custo por Km Rodado'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Km por litro (km/L)'),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  kmPorLitro = value;
                },
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Km rodados'),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  kmRodados = value;
                },
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Preço da gasolina (R\$ por litro)'),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  precoGasolina = value;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (kmPorLitro.isNotEmpty && kmRodados.isNotEmpty && precoGasolina.isNotEmpty) {
                  try {
                    final double consumo = double.parse(kmPorLitro);
                    final double distancia = double.parse(kmRodados);
                    final double preco = double.parse(precoGasolina);
                    setState(() {
                      _custoPorKm = (preco / consumo);
                    });
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Valores inválidos.')),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Por favor, preencha todos os campos.')),
                  );
                }
                Navigator.of(context).pop();
              },
              child: const Text('Calcular'),
            ),
          ],
        );
      },
    );
  }

  void _logout() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gastos de ${widget.username}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _abrirDialogoAdicionarGasto,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                _buildProfilePicture(), 
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Gasto no mês',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          Text(
                            _valorOculto ? 'R\$----.----' : 'R\$${_totalGastos.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: Icon(
                              _valorOculto ? Icons.visibility_off : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _valorOculto = !_valorOculto;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _abrirDialogoCalcularKmRodados,
                        child: const Text('Calcular Custo por KM Rodado'),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _custoPorKm > 0
                            ? 'Custo por Km Rodado: R\$${_custoPorKm.toStringAsFixed(2)}'
                            : '',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _gastos.isEmpty
                ? const Center(
                    child: Text(
                      'Nenhum gasto cadastrado.',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  )
                : Expanded(
                    child: ListView.builder(
                      itemCount: _gastos.length,
                      itemBuilder: (context, index) {
                        return GastoTile(
                          titulo: _gastos[index]['titulo'],
                          valor: 'R\$${_gastos[index]['valor'].toStringAsFixed(2)}',
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: ''),
        ],
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: false,
        showSelectedLabels: false,
      ),
    );
  }
}

class GastoTile extends StatelessWidget {
  final String titulo;
  final String valor;

  const GastoTile({super.key, required this.titulo, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.monetization_on, color: Colors.red),
        title: Text(titulo),
        trailing: Text(valor, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
