// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously, avoid_print

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class HomeTab extends StatefulWidget {
  final bool isAdmin;

  const HomeTab({super.key, this.isAdmin = false});

  @override
  _HomeTabState createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  String _userName = '';
  DateTime _selectedDate = DateTime.now();
  bool _showGenerateReportButton = false;
  pw.Font? robotoRegular;
  pw.Font? robotoBold;

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadFonts();
  }

  void _loadUserName() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String collectionPath = widget.isAdmin ? 'admins' : 'operators';
      final userDocRef =
          FirebaseFirestore.instance.collection(collectionPath).doc(user.uid);
      final snapshot = await userDocRef.get();
      if (snapshot.exists) {
        setState(() {
          _userName = snapshot.data()?['name'] ?? '';
        });
      }
    }
  }

  void _showAddProductPopup(BuildContext context) {
    if (!widget.isAdmin) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Añadir', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                // ignore: prefer_const_constructors
                _buildOptionItem(context, '🚚 Camiones', AddVehicleScreen()),
                _buildOptionItem(context, '🛠 Varios', const AddMaterialScreen()),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOptionItem(BuildContext context, String option, Widget screen) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop();
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => screen));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(option,
            style: const TextStyle(
                color: Colors.blue, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _selectDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
        _showGenerateReportButton = true;
      });
    }
  }

  void _loadFonts() async {
    final fontRegularData =
        await rootBundle.load("assets/fonts/Roboto-Regular.ttf");
    final fontBoldData = await rootBundle.load("assets/fonts/Roboto-Bold.ttf");
    setState(() {
      robotoRegular = pw.Font.ttf(fontRegularData.buffer.asByteData());
      robotoBold = pw.Font.ttf(fontBoldData.buffer.asByteData());
    });
  }

  void _generateReport(BuildContext context) async {
    final pdf = pw.Document();
    String fullName = '';

    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDocRef =
          FirebaseFirestore.instance.collection('operators').doc(user.uid);
      final adminDocRef =
          FirebaseFirestore.instance.collection('admins').doc(user.uid);
      final userSnapshot = await userDocRef.get();
      final adminSnapshot = await adminDocRef.get();

      if (userSnapshot.exists) {
        fullName = userSnapshot.data()?['name'] ?? '';
      } else if (adminSnapshot.exists) {
        fullName = adminSnapshot.data()?['name'] ?? '';
      }
    }

    final trucksSnapshot =
        await FirebaseFirestore.instance.collection('trucks').get();

    List<Map<String, dynamic>> trucksData = [];
    for (var doc in trucksSnapshot.docs) {
      // ignore: unnecessary_cast
      var data = doc.data() as Map<String, dynamic>;
      Map<String, dynamic> wearLevelHistorial = data['historialDesgaste'] ?? {};
      String fechaClave = DateFormat('yyyy-MM-dd').format(_selectedDate);

      if (wearLevelHistorial.containsKey(fechaClave)) {
        double wearLevelParaFecha = wearLevelHistorial[fechaClave].toDouble();
        String historicalStatus =
            wearLevelParaFecha <= 2 ? "Requiere atención" : "Operativo";
        var truckData = {
          ...data,
          'wearLevel': wearLevelParaFecha,
          'status': historicalStatus,
          'lastUpdated': _selectedDate,
        };
        trucksData.add(truckData);
      }
    }

    if (trucksData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              "🤷‍♂️ No hay datos históricos disponibles para la fecha seleccionada.")));
      return;
    }

    final columnOrder = [
      'brand',
      'model',
      'color',
      'plate',
      'year',
      'mileage',
      'wearLevel',
      'status',
      'comments'
    ];
    final headers = [
      'Marca',
      'Modelo',
      'Color',
      'Placa',
      'Año',
      'Kilometraje',
      'Nivel de desgaste',
      'Estado',
      'Comentarios'
    ];
    final data = trucksData
        .map((truck) => columnOrder
            .map((column) => truck[column]?.toString() ?? '')
            .toList())
        .toList();

    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(
          base: robotoRegular ?? pw.Font.helvetica(),
          bold: robotoBold ?? pw.Font.helveticaBold(),
        ),
        header: (pw.Context context) {
          return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text("TuFlota v0.0.1",
                    style: pw.TextStyle(
                        fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.Text('Instituto Municipal del Aseo Urbano (IMASEO)',
                    style: pw.TextStyle(
                        fontSize: 12, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 5),
                pw.Text(
                    'Reporte de camiones hasta ${DateFormat('dd-MM-yyyy').format(_selectedDate)}',
                    style: const pw.TextStyle(fontSize: 20)),
              ]);
        },
        build: (pw.Context context) => [
          // ignore: deprecated_member_use
          pw.Table.fromTextArray(
            context: context,
            cellAlignment: pw.Alignment.centerLeft,
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            headerHeight: 25,
            cellHeight: 30,
            headerStyle: pw.TextStyle(
                color: PdfColors.black, fontWeight: pw.FontWeight.bold),
            headers: headers,
            data: data.map((row) {
              return row.map((cell) {
                int cellIndex = row.indexOf(cell);
                if (cellIndex == columnOrder.indexOf('status') &&
                    cell == "Requiere atención") {
                  return pw.Container(
                    decoration: const pw.BoxDecoration(color: PdfColors.red),
                    padding: const pw.EdgeInsets.all(2),
                    child: pw.Text(cell,
                        style: const pw.TextStyle(color: PdfColors.black)),
                  );
                } else {
                  return pw.Text(cell);
                }
              }).toList();
            }).toList(),
            columnWidths: { for (var index in List.generate(headers.length, (index) => index)) index : const pw.FlexColumnWidth() },
          ),
        ],
        footer: (pw.Context context) {
          return pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Generado por $fullName',
                  style: const pw.TextStyle(fontSize: 12)),
              pw.Text(
                  'Generado el ${DateFormat('dd-MM-yy – kk:mm').format(DateTime.now())}',
                  style: const pw.TextStyle(fontSize: 12)),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          title: Text('¡Bienvenido, $_userName! 👋'),
        ),
        body: Container(
          color: Colors.white,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.isAdmin)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => _showAddProductPopup(context),
                    child: const Text('🟢 Añadir nuevo artículo'),
                  ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => _selectDate(context),
                  child: const Text('🔎 Consultar reportes'),
                ),
                const SizedBox(height: 16),
                if (_showGenerateReportButton)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.green,
                    ),
                    onPressed: () => _generateReport(context),
                    child: const Text('📋 Generar reporte PDF'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AddVehicleScreen extends StatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  _AddVehicleScreenState createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final TextEditingController brandController = TextEditingController();
  final TextEditingController modelController = TextEditingController();
  final TextEditingController mileageController = TextEditingController();
  final TextEditingController colorController = TextEditingController();
  final TextEditingController plateController = TextEditingController();
  int selectedYear = DateTime.now().year;
  double wearLevel = 5;
  String selectedStatus = 'Operativo';
  final TextEditingController commentsController = TextEditingController();

  List<int> yearsList = List.generate(
      DateTime.now().year - 1899, (index) => DateTime.now().year - index);
  List<String> statusList = ['Operativo', 'Inoperativo', 'Requiere atención'];

  void saveVehicleData(BuildContext context) {
    String brand = brandController.text.trim();
    String model = modelController.text.trim();
    String plate = plateController.text.trim();
    int mileage = int.tryParse(mileageController.text) ?? 0;
    String color = colorController.text.trim();
    String comments = commentsController.text.trim();

    if (brand.isEmpty ||
        model.isEmpty ||
        plate.isEmpty ||
        mileage == 0 ||
        color.isEmpty ||
        comments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('❌ Por favor, completa todos los campos.'),
      ));
      return;
    }

    CollectionReference trucksRef =
        FirebaseFirestore.instance.collection("trucks");

    trucksRef.add({
      "brand": brand,
      "model": model,
      "plate": plate,
      "mileage": mileage,
      "color": color,
      "year": selectedYear,
      "wearLevel": wearLevel,
      "status": selectedStatus,
      "comments": comments,
      "lastUpdated": FieldValue.serverTimestamp(),
    }).then((docReference) {
      print("Saved with ID: ${docReference.id}");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('✅ Camión guardado exitosamente'),
      ));
      Navigator.pop(context);
    }).catchError((error) {
      print("Error saving: $error");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('❌ Error al guardar el camión: $error'),
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🚚 Agregar camión'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: brandController,
              decoration: const InputDecoration(labelText: 'Marca del camión'),
            ),
            TextFormField(
              controller: modelController,
              decoration: const InputDecoration(labelText: 'Modelo del camión'),
            ),
            TextFormField(
              controller: mileageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText:
                      'Kilometraje del camión (Km, sin puntos. Ej: 12000)'),
            ),
            TextFormField(
              controller: colorController,
              decoration: const InputDecoration(labelText: 'Color del camión'),
            ),
            TextFormField(
              controller: plateController,
              decoration: const InputDecoration(labelText: 'Placa del camión'),
            ),
            Row(
              children: [
                const Text('Año:'),
                const SizedBox(width: 16),
                DropdownButton<int>(
                  value: selectedYear,
                  items: yearsList.map((year) {
                    return DropdownMenuItem<int>(
                      value: year,
                      child: Text(year.toString()),
                    );
                  }).toList(),
                  onChanged: (int? newValue) {
                    if (newValue != null) {
                      setState(() {
                        selectedYear = newValue;
                      });
                    }
                  },
                  hint: const Text('Seleccione un año'),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Salud general (1 es mal estado, 10 como nuevo):',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Slider(
                  value: wearLevel,
                  onChanged: (double value) {
                    setState(() {
                      wearLevel = value;
                    });
                  },
                  min: 1,
                  max: 10,
                  divisions: 9,
                  label: wearLevel.toStringAsFixed(1),
                ),
                Text('Nivel actual: ${wearLevel.toStringAsFixed(1)}'),
              ],
            ),
            DropdownButton<String>(
              value: selectedStatus,
              items: statusList.map((status) {
                return DropdownMenuItem<String>(
                  value: status,
                  child: Text(status),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    selectedStatus = newValue;
                  });
                }
              },
              hint: const Text('Seleccione un estado'),
            ),
            TextFormField(
              controller: commentsController,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Comentarios'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () => saveVehicleData(context),
              child: const Text('💾 Guardar camión'),
            ),
          ],
        ),
      ),
    );
  }
}

/*class AddInfraestructureScreen extends StatefulWidget {
    @override
    _AddInfraestructureScreenState createState() => _AddInfraestructureScreenState();
  }

  class _AddInfraestructureScreenState extends State<AddInfraestructureScreen> {
    final TextEditingController establishmentNameController = TextEditingController();
    final TextEditingController municipalityController = TextEditingController();
    final TextEditingController truckCapacityController = TextEditingController();
    int selectedYear = DateTime.now().year;

    void saveInfraestructureData(BuildContext context) {
      String establishmentName = establishmentNameController.text.trim();
      String municipality = municipalityController.text.trim();
      int truckCapacity = int.tryParse(truckCapacityController.text) ?? 0;

      if (establishmentName.isEmpty || municipality.isEmpty || truckCapacity == 0) {
        return;
      }

      Timestamp timestamp = Timestamp.now();

      CollectionReference infraestructuresRef = FirebaseFirestore.instance.collection("infraestructures");
      infraestructuresRef.add({
        "establishmentName": establishmentName,
        "municipality": municipality,
        "truckCapacity": truckCapacity,
        "timestamp": timestamp,
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Infraestructura guardada exitosamente'),
      ));

      Navigator.pop(context);
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Agregar Infraestructura'),
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: establishmentNameController,
                decoration: InputDecoration(labelText: 'Nombre de establecimiento'),
              ),
              TextFormField(
                controller: municipalityController,
                decoration: InputDecoration(labelText: 'Municipio'),
              ),
              TextFormField(
                controller: truckCapacityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Capacidad de camiones'),
              ),
              ElevatedButton(
                onPressed: () => saveInfraestructureData(context),
                child: Text('Guardar Infraestructura'),
              ),
            ],
          ),
        ),
      );
    }
  }*/

class AddMaterialScreen extends StatefulWidget {
  const AddMaterialScreen({super.key});

  @override
  _AddMaterialScreenState createState() => _AddMaterialScreenState();
}

class _AddMaterialScreenState extends State<AddMaterialScreen> {
  final TextEditingController materialNameController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController commentsController = TextEditingController();
  double wearLevel = 5.0;
  List<String> elementsList = [
    'Madera',
    'Metal',
    'Acero inoxidable',
    'Cobre',
    'Bronce',
    'Oro'
  ];
  Map<String, bool> selectedElements = {};
  Map<String, TextEditingController> elementWeightControllers = {};

  @override
  void initState() {
    super.initState();
    for (var element in elementsList) {
      selectedElements[element] = false;
      elementWeightControllers[element] = TextEditingController();
    }
  }

  void saveMaterialData(BuildContext context) {
    String materialName = materialNameController.text.trim();
    double weight = double.tryParse(weightController.text) ?? 0.0;
    String comments = commentsController.text.trim();
    Map<String, double> elementsWeights = {};

    for (var element in elementsList) {
      if (selectedElements[element]!) {
        elementsWeights[element] =
            double.tryParse(elementWeightControllers[element]!.text) ?? 0.0;
      }
    }

    if (materialName.isEmpty || weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('❗ Por favor, complete todos los campos necesarios.'),
      ));
      return;
    }

    FirebaseFirestore.instance.collection('materials').add({
      'materialName': materialName,
      'weight': weight,
      'comments': comments,
      'elementsWeights': elementsWeights,
      'wearLevel': wearLevel,
      'lastUpdated': FieldValue.serverTimestamp(),
    }).then((result) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('✅ Producto guardado con éxito.'),
      ));
      Navigator.pop(context);
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('❌ Error al guardar el producto: $error'),
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agregar producto'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextFormField(
              controller: materialNameController,
              decoration: const InputDecoration(labelText: 'Nombre del producto'),
            ),
            TextFormField(
              controller: weightController,
              decoration: const InputDecoration(labelText: 'Peso (en gramos)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            const Text('Elementos:'),
            Column(
              children: elementsList.map((element) {
                return Row(
                  children: [
                    Expanded(
                      child: CheckboxListTile(
                        title: Text(element),
                        value: selectedElements[element],
                        onChanged: (bool? value) {
                          setState(() {
                            selectedElements[element] = value!;
                          });
                        },
                      ),
                    ),
                    if (selectedElements[element]!)
                      Expanded(
                        child: TextFormField(
                          controller: elementWeightControllers[element],
                          decoration: InputDecoration(
                              labelText: 'Peso de $element (gramos)'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                  ],
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            const Text('Nivel de desgaste:'),
            Slider(
              min: 0,
              max: 10,
              divisions: 10,
              value: wearLevel,
              label: wearLevel.toStringAsFixed(1),
              onChanged: (value) {
                setState(() {
                  wearLevel = value;
                });
              },
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: commentsController,
              decoration: const InputDecoration(labelText: 'Comentarios'),
              maxLines: 3,
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () => saveMaterialData(context),
              child: const Text('💾 Guardar producto'),
            ),
          ],
        ),
      ),
    );
  }
}
