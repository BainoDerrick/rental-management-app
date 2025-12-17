import 'package:flutter/material.dart';
import 'package:rental_management_app/models/tenant_model.dart';

class TenantCard extends StatelessWidget {
  final Tenant tenant;

  TenantCard({required this.tenant});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(tenant.name),
        subtitle: Text(tenant.houseNumber),
        trailing: Icon(Icons.arrow_forward),
      ),
    );
  }
}