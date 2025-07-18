import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MedicationScreen extends StatefulWidget {
  final String pillboxId;

  const MedicationScreen({Key? key, required this.pillboxId}) : super(key: key);

  @override
  State<MedicationScreen> createState() => _MedicationScreenState();
}

class _MedicationScreenState extends State<MedicationScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _compartmentController = TextEditingController();
  final TextEditingController _doseController = TextEditingController();
  final TextEditingController _intervalHoursController = TextEditingController();
  final TextEditingController _daysController = TextEditingController();
  bool _isLoading = false;

  Future<void> _saveMedication() async {
    final name = _nameController.text.trim();
    final compartment = _compartmentController.text.trim();
    final dose = _doseController.text.trim();
    final intervalHours = int.tryParse(_intervalHoursController.text.trim());
    final days = int.tryParse(_daysController.text.trim());

    // Validaciones
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre del medicamento es obligatorio')),
      );
      return;
    }

    if (compartment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El número de compartimiento es obligatorio')),
      );
      return;
    }

    if (dose.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La dosis es obligatoria')),
      );
      return;
    }

    if (intervalHours == null || intervalHours <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Las horas entre tomas deben ser un número válido mayor a 0')),
      );
      return;
    }

    if (days == null || days <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Los días deben ser un número válido mayor a 0')),
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

      // Calcular total de dosis
      final totalDoses = (days * 24) ~/ intervalHours;

      // Crear documento con ID automático
      final medicationRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('pillboxes')
          .doc(widget.pillboxId)
          .collection('medications')
          .doc();

      await medicationRef.set({
        'name': name,
        'compartment': compartment,
        'dose': dose,
        'intervalHours': intervalHours,
        'days': days,
        'totalDoses': totalDoses,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Limpiar formulario
      _nameController.clear();
      _compartmentController.clear();
      _doseController.clear();
      _intervalHoursController.clear();
      _daysController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Medicamento guardado exitosamente')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteMedication(String medicationId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('pillboxes')
          .doc(widget.pillboxId)
          .collection('medications')
          .doc(medicationId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Medicamento eliminado')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar: $e')),
      );
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
      appBar: AppBar(
        title: Text('Medicamentos - ${widget.pillboxId}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Formulario
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Agregar medicamento',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del medicamento *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _compartmentController,
                      decoration: const InputDecoration(
                        labelText: 'Número de compartimiento *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _doseController,
                      decoration: const InputDecoration(
                        labelText: 'Dosis por toma *',
                        hintText: 'Ej: 1 pastilla, 15 ml',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _intervalHoursController,
                            decoration: const InputDecoration(
                              labelText: 'Cada X horas *',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _daysController,
                            decoration: const InputDecoration(
                              labelText: 'Días *',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton(
                              onPressed: _saveMedication,
                              child: const Text('Guardar medicamento'),
                            ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Lista de medicamentos
            const Text(
              'Medicamentos registrados:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .collection('pillboxes')
                    .doc(widget.pillboxId)
                    .collection('medications')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final medications = snapshot.data?.docs ?? [];

                  if (medications.isEmpty) {
                    return const Center(
                      child: Text('No hay medicamentos registrados'),
                    );
                  }

                  return ListView.builder(
                    itemCount: medications.length,
                    itemBuilder: (context, index) {
                      final medication = medications[index].data() as Map<String, dynamic>;
                      final medicationId = medications[index].id;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(medication['name'] ?? ''),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Compartimiento: ${medication['compartment'] ?? ''}'),
                              Text('Dosis: ${medication['dose'] ?? ''}'),
                              Text('Cada ${medication['intervalHours'] ?? ''} horas por ${medication['days'] ?? ''} días'),
                              Text('Total de tomas: ${medication['totalDoses'] ?? ''}'),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteMedication(medicationId),
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