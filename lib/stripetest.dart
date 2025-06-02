import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class SubscriptionPlan {
  final String name;
  final String planType;
  final String description;
  final String price;
  final String stripePriceId;
  final List<String> features;
  final int id; // Added plan ID

  SubscriptionPlan({
    required this.name,
    required this.planType,
    required this.description,
    required this.price,
    required this.stripePriceId,
    required this.features,
    required this.id,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Unnamed Plan',
      planType: json['plan_type'] ?? 'Unknown',
      description: json['description'] ?? 'No description available',
      price: json['price']?.toString() ?? '0.00',
      stripePriceId: json['stripe_price_id'] ?? '',
      features: (json['features'] as String?)?.split(',').map((e) => e.trim()).toList() ?? [],
    );
  }
}

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  late Future<List<SubscriptionPlan>> _plans;

  Future<List<SubscriptionPlan>> fetchPlans() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token');

    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('Access token is missing or empty.');
    }

    final response = await http.get(
      Uri.parse('http://192.168.20.29:8001/api/subscription-plans/'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((item) => SubscriptionPlan.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load plans: ${response.statusCode}');
    }
  }

  Future<void> _initiateCheckout(int planId) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token');

    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('Access token is missing or empty.');
    }

    final response = await http.post(
      Uri.parse('http://192.168.20.29:8001/api/stripe/checkout/'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: json.encode({'plan_id': planId}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final jsonResponse = json.decode(response.body);
      final checkoutUrl = jsonResponse['checkout_url'] as String?;
      if (checkoutUrl != null && await canLaunchUrl(Uri.parse(checkoutUrl))) {
        await launchUrl(Uri.parse(checkoutUrl), mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not launch checkout URL');
      }
    } else {
      throw Exception('Failed to initiate checkout: ${response.statusCode}');
    }
  } catch (e) {
    if (mounted) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Error'),
          content: Text('Failed to initiate checkout: $e'),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    }
  }
}

  @override
  void initState() {
    super.initState();
    _plans = fetchPlans();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Subscription Plans'),
      ),
      child: FutureBuilder<List<SubscriptionPlan>>(
        future: _plans,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CupertinoActivityIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${snapshot.error}', style: const TextStyle(color: CupertinoColors.destructiveRed)),
                  const SizedBox(height: 16),
                  CupertinoButton(
                    child: const Text('Retry'),
                    onPressed: () {
                      setState(() {
                        _plans = fetchPlans();
                      });
                    },
                  ),
                ],
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No plans found.'));
          } else {
            final plans = snapshot.data!;
            return ListView.builder(
              itemCount: plans.length,
              itemBuilder: (context, index) {
                final plan = plans[index];
                return CupertinoListTile(
                  plan: plan,
                  onSelect: () => _initiateCheckout(plan.id),
                );
              },
            );
          }
        },
      ),
    );
  }
}

class CupertinoListTile extends StatelessWidget {
  final SubscriptionPlan plan;
  final VoidCallback onSelect;

  const CupertinoListTile({super.key, required this.plan, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      onPressed: onSelect,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: CupertinoColors.separator)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(plan.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('${plan.planType} Plan', style: const TextStyle(color: CupertinoColors.inactiveGray)),
            const SizedBox(height: 4),
            Text('\$${plan.price}', style: const TextStyle(fontSize: 16, color: CupertinoColors.systemBlue)),
          ],
        ),
      ),
    );
  }
}