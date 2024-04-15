import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class Material {
  final String id;
  final String comments;
  final Map<String, dynamic> elementsWeights;
  final String materialName;
  final List<dynamic> selectedElements;
  final Timestamp timestamp;
  final double weight;
  final double wearLevel;
  final DateTime lastUpdated;

  Material({
    required this.id,
    required this.comments,
    required this.elementsWeights,
    required this.materialName,
    required this.selectedElements,
    required this.timestamp,
    required this.weight,
    required this.wearLevel,
    required this.lastUpdated,
  });
}

class ToolsTab extends StatefulWidget {
  final bool isAdmin;

  ToolsTab({required this.isAdmin});

  @override
  _ToolsTabState createState() => _ToolsTabState();
}

class _ToolsTabState extends State<ToolsTab> {
  final TextEditingController _searchController = TextEditingController();
  List<Material> _allMaterials = [];
  List<Material> _filteredMaterials = [];

  @override
  void initState() {
    super.initState();
    _loadMaterials();
  }

  void _loadMaterials() async {
    final snapshot = await FirebaseFirestore.instance.collection('materials').get();
    final materials = snapshot.docs.map((doc) {
      var data = doc.data() as Map<String, dynamic>;
      return Material(
        id: doc.id,
        comments: data['comments'] ?? '',
        elementsWeights: data['elementsWeights'] ?? {},
        materialName: data['materialName'] ?? '',
        selectedElements: data['selectedElements'] ?? [],
        timestamp: data['timestamp'] ?? Timestamp.now(),
        weight: (data['weight'] ?? 0).toDouble(),
        wearLevel: data['wearLevel'] ?? 0.0,
        lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
      );
    }).toList();

    setState(() {
      _allMaterials = materials;
      _filteredMaterials = materials;
    });
  }

  void _searchMaterials(String searchTerm) {
    setState(() {
      if (searchTerm.isEmpty) {
        _filteredMaterials = _allMaterials;
      } else {
        final lowerCaseSearchTerm = searchTerm.toLowerCase();
        _filteredMaterials = _allMaterials.where((material) {
          return material.materialName.toLowerCase().contains(lowerCaseSearchTerm);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          title: Text('🛠 Productos variados'),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: '🔎 Buscar producto...',
                  suffixIcon: IconButton(
                    icon: Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _searchMaterials('');
                    },
                  ),
                ),
                onChanged: _searchMaterials,
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredMaterials.length,
                itemBuilder: (context, index) {
                  final material = _filteredMaterials[index];
                  return ListTile(
                    title: Text(material.materialName),
                    subtitle: Text('Peso: ${material.weight.toString()} gramos'),
                    onTap: () => _showMaterialDetails(context, material),
                    trailing: widget.isAdmin
                        ? IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmDeleteMaterial(context, material),
                    )
                        : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMaterialDetails(BuildContext context, Material material) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(material.materialName),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Comentarios:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(material.comments),
                Text('Peso:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('${material.weight} gramos'),
                Text('Elementos:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(material.elementsWeights.entries.map((e) => '${e.key}: ${e.value} gramos').join(', ')),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Nivel de desgaste:', style: TextStyle(fontWeight: FontWeight.bold)),
                      LinearProgressIndicator(
                        value: material.wearLevel / 10,
                        backgroundColor: Colors.grey,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          material.wearLevel <= 3 ? Colors.red : material.wearLevel <= 6 ? Colors.yellow : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                Text('Última actualización:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(DateFormat('dd-MM-yyyy – kk:mm').format(material.lastUpdated)),
              ],
            ),
          ),
          actions: <Widget>[
            if (widget.isAdmin)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: Text('✏ Editar'),
                onPressed: () => _editMaterial(context, material),
              ),
            ElevatedButton(
              child: Text('Cerrar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _editMaterial(BuildContext context, Material material) {
    TextEditingController commentsController = TextEditingController(text: material.comments);
    TextEditingController weightController = TextEditingController(text: material.weight.toString());
    int selectedWearLevel = material.wearLevel.round().clamp(1, 10);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Editar ${material.materialName}'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: commentsController,
                  decoration: InputDecoration(labelText: 'Comentarios'),
                ),
                TextField(
                  controller: weightController,
                  decoration: InputDecoration(labelText: 'Peso'),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
                DropdownButton<int>(
                  value: selectedWearLevel,
                  onChanged: (newValue) {
                    setState(() {
                      selectedWearLevel = newValue!;
                    });
                  },
                  items: List.generate(10, (index) => index + 1)
                      .map<DropdownMenuItem<int>>((int value) {
                    return DropdownMenuItem<int>(
                      value: value,
                      child: Text(value.toString()),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: Text('💾 Guardar cambios'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                await FirebaseFirestore.instance.collection('materials').doc(material.id).update({
                  'comments': commentsController.text,
                  'weight': double.tryParse(weightController.text) ?? material.weight,
                  'wearLevel': selectedWearLevel.toDouble(),
                }).then((value) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("✅ Producto actualizado con éxito.")));
                  _loadMaterials();
                }).catchError((error) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ Error al actualizar el material.")));
                });
              },
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteMaterial(BuildContext context, Material material) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Eliminar material'),
          content: Text('¿Estás seguro de que quieres eliminar ${material.materialName}?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Eliminar'),
              onPressed: () {
                FirebaseFirestore.instance.collection('materials').doc(material.id).delete().then((_) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("✅ Producto eliminado con éxito.")));
                  _loadMaterials();
                }).catchError((error) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ Error al eliminar el producto: $error")));
                });
              },
            ),
          ],
        );
      },
    );
  }
}
