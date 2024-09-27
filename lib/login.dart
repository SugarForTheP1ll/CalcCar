import 'package:flutter/material.dart';
import 'database/database_manager.dart';
import 'main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String _nome = '';
  String _senha = '';
  bool _isLogin = true;

  final DatabaseManager _databaseManager = DatabaseManager();

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (_isLogin) {
        bool loginSucesso = await _databaseManager.loadAccount(_nome, _senha);
        if (loginSucesso) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => TelaGastos(username: _nome)),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nome ou senha incorretos.')),
          );
        }
      } else {
        await _databaseManager.saveAccount(_nome, _senha);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conta cadastrada com sucesso! Faça login agora.')),
        );
        setState(() {
          _isLogin = true;
        });
      }
    }
  }

  void _alternarLoginCadastro() {
    setState(() {
      _isLogin = !_isLogin;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 100),
            const Text(
              'Bem-Vindo ao CalcCar',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isLogin ? 'Login' : 'Criar Conta',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Nome'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira seu nome';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _nome = value!;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Senha'),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira sua senha';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _senha = value!;
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _submit,
                      child: Text(_isLogin ? 'Entrar' : 'Cadastrar'),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: _alternarLoginCadastro,
                      child: Text(
                        _isLogin ? 'Criar Conta' : 'Já tem conta? Entre aqui',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
