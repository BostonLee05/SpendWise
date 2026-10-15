import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const String apiBaseUrl = 'http://10.0.2.2:8000';

class UserModel {
  final int id;
  final String name;
  final String email;
  final String userType;
  final double monthlyIncome;
  final double monthlyBudget;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.userType,
    required this.monthlyIncome,
    this.monthlyBudget = 0.0,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      userType: json['user_type'] as String,
      monthlyIncome: (json['monthly_income'] ?? 0.0).toDouble(),
      monthlyBudget: (json['monthly_budget'] ?? 0.0).toDouble(),
    );
  }
}

class ExpenseModel {
  final int id;
  final double amount;
  final String category;
  final String description;
  final String frequency;
  final DateTime expenseDate;

  const ExpenseModel({
    required this.id,
    required this.amount,
    required this.category,
    required this.description,
    required this.frequency,
    required this.expenseDate,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id'] as int,
      amount: (json['amount'] as num).toDouble(),
      category: json['category'] as String,
      description: json['description'] as String,
      frequency: json['frequency'] as String,
      expenseDate: DateTime.parse(json['expense_date'] as String),
    );
  }
}

class CategorySummaryModel {
  final String category;
  final double total;

  const CategorySummaryModel({
    required this.category,
    required this.total,
  });

  factory CategorySummaryModel.fromJson(Map<String, dynamic> json) {
    return CategorySummaryModel(
      category: json['category'] as String,
      total: (json['total'] ?? 0.0).toDouble(),
    );
  }
}

class DashboardModel {
  final double monthlyIncome;
  final double monthlyBudget;
  final double totalSpent;
  final double remaining;
  final double budgetRemaining;
  final List<ExpenseModel> expenses;
  final List<CategorySummaryModel> categoryTotals;

  const DashboardModel({
    required this.monthlyIncome,
    required this.monthlyBudget,
    required this.totalSpent,
    required this.remaining,
    required this.budgetRemaining,
    required this.expenses,
    required this.categoryTotals,
  });

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    final items = (json['expenses'] as List<dynamic>? ?? [])
        .map((item) => ExpenseModel.fromJson(item as Map<String, dynamic>))
        .toList();

    final categoryTotals = (json['category_totals'] as List<dynamic>? ?? [])
        .map((item) => CategorySummaryModel.fromJson(item as Map<String, dynamic>))
        .toList();

    return DashboardModel(
      monthlyIncome: (json['monthly_income'] ?? 0.0).toDouble(),
      monthlyBudget: (json['monthly_budget'] ?? 0.0).toDouble(),
      totalSpent: (json['total_spent'] ?? 0.0).toDouble(),
      remaining: (json['remaining'] ?? 0.0).toDouble(),
      budgetRemaining: (json['budget_remaining'] ?? 0.0).toDouble(),
      expenses: items,
      categoryTotals: categoryTotals,
    );
  }
}

class ApiService {
  static Future<Map<String, dynamic>> _handleResponse(http.Response response) async {
    final decoded = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded is Map<String, dynamic> ? decoded : {'data': decoded};
    }

    final message = decoded is Map && decoded.containsKey('detail')
        ? decoded['detail']
        : 'Request failed';
    throw Exception(message.toString());
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$apiBaseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String userType,
    required double monthlyIncome,
    required double monthlyBudget,
  }) async {
    final response = await http.post(
      Uri.parse('$apiBaseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'user_type': userType,
        'monthly_income': monthlyIncome,
        'monthly_budget': monthlyBudget,
      }),
    );

    return _handleResponse(response);
  }

  static Future<UserModel> getCurrentUser(String token) async {
    final response = await http.get(
      Uri.parse('$apiBaseUrl/me'),
      headers: {'Authorization': 'Bearer $token'},
    );

    final decoded = await _handleResponse(response);
    return UserModel.fromJson(decoded);
  }

  static Future<DashboardModel> fetchDashboard(String token) async {
    final response = await http.get(
      Uri.parse('$apiBaseUrl/dashboard'),
      headers: {'Authorization': 'Bearer $token'},
    );

    final decoded = await _handleResponse(response);
    return DashboardModel.fromJson(decoded);
  }

  static Future<Map<String, dynamic>> createExpense({
    required String token,
    required double amount,
    required String category,
    required String description,
    required String frequency,
  }) async {
    final response = await http.post(
      Uri.parse('$apiBaseUrl/expenses'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'amount': amount,
        'category': category,
        'description': description,
        'frequency': frequency,
      }),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> updateExpense({
    required String token,
    required int expenseId,
    required double amount,
    required String category,
    required String description,
    required String frequency,
  }) async {
    final response = await http.put(
      Uri.parse('$apiBaseUrl/expenses/$expenseId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'amount': amount,
        'category': category,
        'description': description,
        'frequency': frequency,
      }),
    );

    return _handleResponse(response);
  }

  static Future<UserModel> updateBudget({
    required String token,
    required double monthlyBudget,
  }) async {
    final response = await http.put(
      Uri.parse('$apiBaseUrl/budget'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'monthly_budget': monthlyBudget}),
    );

    final decoded = await _handleResponse(response);
    return UserModel.fromJson(decoded);
  }

  static Future<void> deleteExpense(String token, int expenseId) async {
    final response = await http.delete(
      Uri.parse('$apiBaseUrl/expenses/$expenseId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    await _handleResponse(response);
  }
}

void main() {
  runApp(const SpendWiseApp());
}

class SpendWiseApp extends StatelessWidget {
  const SpendWiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SpendWise',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const AuthScreen(),
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedUserType = 'employed';
  final _incomeController = TextEditingController(text: '2500');
  final _budgetController = TextEditingController(text: '2000');
  bool _isSubmitting = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      if (isLogin) {
        final result = await ApiService.login(
          _emailController.text.trim(),
          _passwordController.text,
        );
        final token = result['access_token'] as String;
        final user = await ApiService.getCurrentUser(token);
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => DashboardScreen(token: token, user: user),
          ),
        );
      } else {
        await ApiService.register(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          userType: _selectedUserType,
          monthlyIncome: double.tryParse(_incomeController.text) ?? 0,
          monthlyBudget: double.tryParse(_budgetController.text) ?? 0,
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration successful. Please log in.')),
        );
        setState(() => isLogin = true);
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: SizedBox(
                    width: 420,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isLogin ? 'Welcome back' : 'Create account',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isLogin
                              ? 'Track your money with SpendWise.'
                              : 'Set up your budget profile.',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 24),
                        if (!isLogin) ...[
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(labelText: 'Full name'),
                            validator: (value) =>
                                value == null || value.trim().length < 2 ? 'Enter a valid name' : null,
                          ),
                          const SizedBox(height: 16),
                        ],
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(labelText: 'Email'),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) return 'Email is required';
                            if (!value.contains('@')) return 'Enter a valid email';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(labelText: 'Password'),
                          validator: (value) =>
                              value == null || value.length < 6 ? 'Minimum 6 characters' : null,
                        ),
                        if (!isLogin) ...[
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedUserType,
                            decoration: const InputDecoration(labelText: 'I am a'),
                            items: const [
                              DropdownMenuItem(value: 'student', child: Text('Student')),
                              DropdownMenuItem(value: 'unemployed', child: Text('Unemployed')),
                              DropdownMenuItem(value: 'employed', child: Text('Employed')),
                            ],
                            onChanged: (value) => setState(() => _selectedUserType = value ?? 'employed'),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _incomeController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Monthly income'),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _budgetController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Monthly budget'),
                          ),
                        ],
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _isSubmitting ? null : _submit,
                            icon: const Icon(Icons.arrow_forward_rounded),
                            label: Text(isLogin ? 'Login' : 'Create account'),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () => setState(() => isLogin = !isLogin),
                          child: Text(
                            isLogin ? 'Need an account? Register' : 'Already have an account? Login',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  final String token;
  final UserModel user;

  const DashboardScreen({super.key, required this.token, required this.user});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _loading = true;
  DashboardModel? _dashboard;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    try {
      final data = await ApiService.fetchDashboard(widget.token);
      if (!mounted) return;
      setState(() {
        _dashboard = data;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
      setState(() => _loading = false);
    }
  }

  Future<void> _addExpense() async {
    final amountController = TextEditingController();
    final descController = TextEditingController();
    String category = 'Food';
    String frequency = 'one_time';

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add expense'),
          content: SizedBox(
            width: 340,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Amount'),
                ),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: const [
                    DropdownMenuItem(value: 'Food', child: Text('Food')),
                    DropdownMenuItem(value: 'Transport', child: Text('Transport')),
                    DropdownMenuItem(value: 'Shopping', child: Text('Shopping')),
                    DropdownMenuItem(value: 'Entertainment', child: Text('Entertainment')),
                    DropdownMenuItem(value: 'Bills', child: Text('Bills')),
                  ],
                  onChanged: (value) => category = value ?? 'Food',
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: frequency,
                  decoration: const InputDecoration(labelText: 'Frequency'),
                  items: const [
                    DropdownMenuItem(value: 'one_time', child: Text('One time')),
                    DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                    DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                  ],
                  onChanged: (value) => frequency = value ?? 'one_time',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                final value = double.tryParse(amountController.text) ?? 0;
                Navigator.pop(context, {
                  'amount': value,
                  'category': category,
                  'description': descController.text.trim(),
                  'frequency': frequency,
                });
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result == null) return;

    try {
      if ((result['amount'] as num).toDouble() <= 0 || (result['description'] as String).isEmpty) {
        throw Exception('Please enter a valid amount and description.');
      }

      await ApiService.createExpense(
        token: widget.token,
        amount: (result['amount'] as num).toDouble(),
        category: result['category'] as String,
        description: result['description'] as String,
        frequency: result['frequency'] as String,
      );
      await _loadDashboard();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  Future<void> _editExpense(ExpenseModel expense) async {
    final amountController = TextEditingController(text: expense.amount.toString());
    final descController = TextEditingController(text: expense.description);
    String category = expense.category;
    String frequency = expense.frequency;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit expense'),
          content: SizedBox(
            width: 340,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Amount'),
                ),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: const [
                    DropdownMenuItem(value: 'Food', child: Text('Food')),
                    DropdownMenuItem(value: 'Transport', child: Text('Transport')),
                    DropdownMenuItem(value: 'Shopping', child: Text('Shopping')),
                    DropdownMenuItem(value: 'Entertainment', child: Text('Entertainment')),
                    DropdownMenuItem(value: 'Bills', child: Text('Bills')),
                  ],
                  onChanged: (value) => category = value ?? expense.category,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: frequency,
                  decoration: const InputDecoration(labelText: 'Frequency'),
                  items: const [
                    DropdownMenuItem(value: 'one_time', child: Text('One time')),
                    DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                    DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                  ],
                  onChanged: (value) => frequency = value ?? expense.frequency,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                final value = double.tryParse(amountController.text) ?? 0;
                Navigator.pop(context, {
                  'amount': value,
                  'category': category,
                  'description': descController.text.trim(),
                  'frequency': frequency,
                });
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );

    if (result == null) return;

    try {
      if ((result['amount'] as num).toDouble() <= 0 || (result['description'] as String).isEmpty) {
        throw Exception('Please enter a valid amount and description.');
      }

      await ApiService.updateExpense(
        token: widget.token,
        expenseId: expense.id,
        amount: (result['amount'] as num).toDouble(),
        category: result['category'] as String,
        description: result['description'] as String,
        frequency: result['frequency'] as String,
      );
      await _loadDashboard();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  Future<void> _updateBudget() async {
    final controller = TextEditingController(
      text: (_dashboard?.monthlyBudget ?? widget.user.monthlyBudget).toString(),
    );

    final result = await showDialog<double>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Monthly budget'),
          content: SizedBox(
            width: 280,
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Budget amount'),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                final value = double.tryParse(controller.text) ?? 0;
                Navigator.pop(context, value);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result == null) return;

    try {
      await ApiService.updateBudget(token: widget.token, monthlyBudget: result);
      await _loadDashboard();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = _dashboard;
    return Scaffold(
      appBar: AppBar(
        title: const Text('SpendWise Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_wallet_rounded),
            tooltip: 'Set monthly budget',
            onPressed: _updateBudget,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const AuthScreen()),
            ),
          ),
        ],
      ),
      body: _loading || dashboard == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboard,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Hi, ${widget.user.name}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _SummaryCard(label: 'Monthly income', value: 'RM ${dashboard.monthlyIncome.toStringAsFixed(2)}'),
                      const SizedBox(width: 12),
                      _SummaryCard(label: 'Spent', value: 'RM ${dashboard.totalSpent.toStringAsFixed(2)}'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _SummaryCard(label: 'Monthly budget', value: 'RM ${dashboard.monthlyBudget.toStringAsFixed(2)}'),
                      const SizedBox(width: 12),
                      _SummaryCard(
                        label: 'Budget left',
                        value: 'RM ${dashboard.budgetRemaining.toStringAsFixed(2)}',
                        accent: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _SummaryCard(
                    label: 'Remaining',
                    value: 'RM ${dashboard.remaining.toStringAsFixed(2)}',
                    accent: true,
                  ),
                  const SizedBox(height: 20),
                  CategoryChart(data: dashboard.categoryTotals),
                  const SizedBox(height: 20),
                  Text(
                    'Recent spending',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (dashboard.expenses.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('No spending added yet. Add your first expense.'),
                      ),
                    )
                  else
                    ...dashboard.expenses.map(
                      (expense) => Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text(expense.category.substring(0, 1).toUpperCase()),
                          ),
                          title: Text(expense.description),
                          subtitle: Text('${expense.category} • ${expense.frequency.replaceAll('_', ' ')}'),
                          trailing: SizedBox(
                            width: 96,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('RM ${expense.amount.toStringAsFixed(2)}'),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      onPressed: () => _editExpense(expense),
                                      icon: const Icon(Icons.edit_outlined, size: 18),
                                      tooltip: 'Edit expense',
                                    ),
                                    IconButton(
                                      onPressed: () async {
                                        final messenger = ScaffoldMessenger.maybeOf(context);
                                        try {
                                          await ApiService.deleteExpense(widget.token, expense.id);
                                          await _loadDashboard();
                                        } catch (error) {
                                          if (!mounted || messenger == null) return;
                                          messenger.showSnackBar(
                                            SnackBar(content: Text(error.toString())),
                                          );
                                        }
                                      },
                                      icon: const Icon(Icons.delete_outline, size: 18),
                                      tooltip: 'Delete expense',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addExpense,
        icon: const Icon(Icons.add),
        label: const Text('Add expense'),
      ),
    );
  }
}

class CategoryChart extends StatelessWidget {
  final List<CategorySummaryModel> data;

  const CategoryChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final maxValue = data.isEmpty
        ? 1.0
        : data.map((entry) => entry.total).reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Spending by category',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (data.isEmpty)
              const Text('No spending data yet.')
            else
              ...data.map((item) {
                final ratio = maxValue <= 0 ? 0.0 : (item.total / maxValue).clamp(0.0, 1.0);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 92,
                        child: Text(
                          item.category,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: LinearProgressIndicator(
                            minHeight: 12,
                            value: ratio,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.indigo.shade400,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 62,
                        child: Text(
                          'RM ${item.total.toStringAsFixed(0)}',
                          textAlign: TextAlign.right,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final bool accent;

  const _SummaryCard({
    required this.label,
    required this.value,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: accent ? Colors.green.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: accent ? Colors.green.shade200 : Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
