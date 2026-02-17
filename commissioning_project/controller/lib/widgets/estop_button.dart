import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/connection_service.dart';

class EstopButton extends StatelessWidget {
  const EstopButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: FloatingActionButton.large(
        heroTag: 'estop',
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        onPressed: () {
          context.read<ConnectionService>().sendEstop();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('EMERGENCY STOP SENT'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        },
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.dangerous, size: 28),
            Text(
              'STOP',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
