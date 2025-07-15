import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PillboxScreen extends StatefulWidget {
  const PillboxScreen({Key? key}) : super(key: key);

  @override
  State<PillboxScreen> createState() => _PillboxScreenState();
}

class _PillboxScreenState extends State<PillboxScreen> {
  final TextEditingController _pillboxIdController = TextEditingController();
  bool _isLoading = false;

  Future<void> _linkPillbox() async {
    final pillboxId = _pillboxIdController.text.trim();
    if (pillboxId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa un ID de pastillero')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario no autenticado')),
        );
        return;
      }

      // Verificar si el pastillero ya existe
      final existingDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('pillboxes')
          .doc(pillboxId)
          .get();

      if (existingDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Este pastillero ya está vinculado')),
        );
        return;
      }

      // Guardar el pastillero
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('pillboxes')
          .doc(pillboxId)
          .set({
        'id': pillboxId,
        'linkedAt': FieldValue.serverTimestamp(),
      });

      _pillboxIdController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pastillero vinculado exitosamente')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Usuario no autenticado')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Mis Pastilleros')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _pillboxIdController,
              decoration: const InputDecoration(
                labelText: 'ID del pastillero',
                hintText: 'Ej: PSTL001',
              ),
            ),
            const SizedBox(height: 16),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _linkPillbox,
                    child: const Text('Vincular pastillero'),
                  ),
            const SizedBox(height: 24),
            const Text(
              'Pastilleros vinculados:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .collection('pillboxes')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final pillboxes = snapshot.data?.docs ?? [];

                  if (pillboxes.isEmpty) {
                    return const Center(
                      child: Text('No hay pastilleros vinculados'),
                    );
                  }

                  return ListView.builder(
                    itemCount: pillboxes.length,
                    itemBuilder: (context, index) {
                      final pillbox = pillboxes[index].data() as Map<String, dynamic>;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text('ID: ${pillbox['id']}'),
                          subtitle: Text(
                            'Vinculado: ${pillbox['linkedAt'] != null ? 'Sí' : 'No'}',
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
} 