import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

class DatabaseManager {
  static const String userBoxName = 'usersBox';
  static const String expensesBoxName = 'expensesBox';

  Future<Box> openUserBox() async {
    return await Hive.openBox(userBoxName);
  }

  Future<Box> openExpensesBox() async {
    return await Hive.openBox(expensesBoxName);
  }

  Future<void> saveAccount(String nome, String senha) async {
    final box = await openUserBox();

    await box.put(nome, {'senha': senha, 'fotoPerfil': ''}); 
    print('Usuário $nome cadastrado com sucesso!');
  }

  Future<bool> loadAccount(String nome, String senha) async {
    final box = await openUserBox();
    final storedData = box.get(nome);

    if (storedData != null && storedData['senha'] == senha) {
      print('Login bem-sucedido para o usuário $nome');
      return true;
    }
    print('Login falhou para o usuário $nome');
    return false;
  }

  Future<void> saveExpense(String username, String titulo, double valor) async {
    final expensesBox = await openExpensesBox();

    List<Map<String, dynamic>> userExpenses = List<Map<String, dynamic>>.from(
        expensesBox.get(username, defaultValue: []));

    userExpenses.add({'titulo': titulo, 'valor': valor});

    await expensesBox.put(username, userExpenses);
  }

  Future<List<Map<String, dynamic>>> loadExpenses(String username) async {
    final expensesBox = await openExpensesBox();

    return List<Map<String, dynamic>>.from(expensesBox.get(username, defaultValue: []));
  }

  Future<void> clearExpenses(String username) async {
    final expensesBox = await openExpensesBox();
    await expensesBox.delete(username);
  }

  Future<void> saveProfilePhoto(String username, String base64Image) async {
    final box = await openUserBox();
    final userData = box.get(username);

    if (userData != null) {
      userData['fotoPerfil'] = base64Image; 
      await box.put(username, userData); 
      print('Foto de perfil atualizada para o usuário $username');
    }
  }

  Future<String?> loadProfilePhoto(String username) async {
    final box = await openUserBox();
    final userData = box.get(username);

    if (userData != null) {
      return userData['fotoPerfil']; 
    }
    return null;
  }
}
