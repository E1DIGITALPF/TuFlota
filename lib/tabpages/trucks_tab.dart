import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

enum SortOption {
  addedDate,
  brandAlphabetical,
}

class Truck {
  final String id;
  String brand;
  String model;
  String plate;
  int year;
  double mileage;
  String color;
  String status;
  double wearLevel;
  DateTime lastUpdated;
  String comments;

  Truck({
    required this.id,
    required this.brand,
    required this.model,
    required this.plate,
    required this.year,
    required this.mileage,
    required this.color,
    required this.status,
    required this.wearLevel,
    required this.lastUpdated,
    required this.comments,
  });
}

class TrucksTab extends StatefulWidget {
  final bool isAdmin;

  TrucksTab({this.isAdmin = false});

  @override
  _TrucksTabState createState() => _TrucksTabState();
}

class _TrucksTabState extends State<TrucksTab> {
  final TextEditingController _searchController = TextEditingController();
  List<Truck> _allTrucks = [];
  List<Truck> _filteredTrucks = [];
  SortOption _sortOption = SortOption.addedDate;
  pw.Font? _robotoRegular;
  pw.Font? _robotoBold;

  @override
  void initState() {
    super.initState();
    _loadTrucks();
    _loadFonts();
  }

  void _loadFonts() async {
    final fontRegularData =
        await rootBundle.load("assets/fonts/Roboto-Regular.ttf");
    final fontBoldData = await rootBundle.load("assets/fonts/Roboto-Bold.ttf");
    setState(() {
      _robotoRegular = pw.Font.ttf(fontRegularData.buffer.asByteData());
      _robotoBold = pw.Font.ttf(fontBoldData.buffer.asByteData());
    });
  }

  void _loadTrucks() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('trucks').get();
    final trucks = snapshot.docs.map((doc) {
      var data = doc.data() as Map<String, dynamic>;
      return Truck(
        id: doc.id,
        brand: data['brand'] ?? '',
        model: data['model'] ?? '',
        plate: data['plate'] ?? '',
        year: data['year'] ?? 0,
        mileage: (data['mileage'] ?? 0).toDouble(),
        color: data['color'] ?? '',
        status: data['status'] ?? '',
        wearLevel: (data['wearLevel'] ?? 0.0).toDouble(),
        lastUpdated: data['lastUpdated'] != null
            ? (data['lastUpdated'] as Timestamp).toDate()
            : DateTime.now(),
        comments: data['comments'] ?? '',
      );
    }).toList();

    if (mounted) {
      setState(() {
        _allTrucks = trucks;
        _filteredTrucks = trucks;
      });
    }
  }

  void _searchTrucks(String searchTerm) {
    if (mounted) {
      setState(() {
        if (searchTerm.isEmpty) {
          _filteredTrucks = _allTrucks;
        } else {
          final lowerCaseSearchTerm = searchTerm.toLowerCase();
          _filteredTrucks = _allTrucks.where((truck) {
            return truck.brand.toLowerCase().contains(lowerCaseSearchTerm) ||
                truck.model.toLowerCase().contains(lowerCaseSearchTerm) ||
                truck.plate.toLowerCase().contains(lowerCaseSearchTerm) ||
                truck.color.toLowerCase().contains(lowerCaseSearchTerm) ||
                truck.status.toLowerCase().contains(lowerCaseSearchTerm) ||
                truck.comments.toLowerCase().contains(lowerCaseSearchTerm);
          }).toList();
        }
        _sortTrucks();
      });
    }
  }

  void _sortTrucks() {
    if (mounted) {
      setState(() {
        switch (_sortOption) {
          case SortOption.addedDate:
            _filteredTrucks
                .sort((a, b) => a.lastUpdated.compareTo(b.lastUpdated));
            break;
          case SortOption.brandAlphabetical:
            _filteredTrucks.sort((a, b) => a.brand.compareTo(b.brand));
            break;
        }
      });
    }
  }

  void _generateReport(Truck truck) async {
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

    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(
          base: _robotoRegular ?? pw.Font.helvetica(),
          bold: _robotoBold ?? pw.Font.helveticaBold(),
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
                pw.Text('Reporte de mantenimiento',
                    style: pw.TextStyle(fontSize: 20)),
                pw.Text(
                    'Marca: ${truck.brand}, Modelo: ${truck.model}, Color: ${truck.color}, Placa: ${truck.plate}',
                    style: pw.TextStyle(fontSize: 16)),
                pw.SizedBox(height: 10),
                pw.Text('Bitácora de mantenimiento',
                    style: pw.TextStyle(
                        fontSize: 16, fontWeight: pw.FontWeight.bold)),
              ]);
        },
        build: (pw.Context context) => [
          pw.Paragraph(text: "Detalles del camión:"),
          pw.Bullet(text: "Marca: ${truck.brand}"),
          pw.Bullet(text: "Modelo: ${truck.model}"),
          pw.Bullet(text: "Año: ${truck.year}"),
          pw.Bullet(text: "Placa: ${truck.plate}"),
          pw.Bullet(text: "Kilometraje: ${truck.mileage} Km"),
          pw.Bullet(text: "Color: ${truck.color}"),
          pw.Bullet(text: "Estado: ${truck.status}"),
          pw.Bullet(text: "Nivel de desgaste: ${truck.wearLevel}"),
          pw.Bullet(
              text:
                  "Última actualización: ${DateFormat('dd-MM-yyyy – kk:mm').format(truck.lastUpdated)}"),
          pw.Bullet(text: "Comentarios: ${truck.comments}"),
        ],
        footer: (pw.Context context) {
          return pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Generado por $fullName',
                  style: pw.TextStyle(fontSize: 12)),
              pw.Text(
                  'Generado el ${DateFormat('dd-MM-yy – kk:mm').format(DateTime.now())}',
                  style: pw.TextStyle(fontSize: 12)),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  void _confirmDeleteTruck(BuildContext context, Truck truck) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Eliminar camión'),
          content: Text(
              '¿Estás seguro de que quieres eliminar el camión ${truck.brand} ${truck.model}?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Eliminar'),
              onPressed: () {
                _deleteTruck(truck.id);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _deleteTruck(String truckId) async {
    await FirebaseFirestore.instance
        .collection('trucks')
        .doc(truckId)
        .delete()
        .then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ Camión eliminado con éxito.")));
      _loadTrucks();
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Error al eliminar el camión: $error")));
    });
  }

  void _navigateAndDisplayEditScreen(BuildContext context, Truck truck) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditTruckScreen(truck: truck),
      ),
    ).then((_) {
      _loadTrucks();
    });
  }

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          title: Text('🚛 Camiones'),
          actions: widget.isAdmin
              ? [
                  PopupMenuButton<SortOption>(
                    onSelected: (option) {
                      setState(() {
                        _sortOption = option;
                        _sortTrucks();
                      });
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: SortOption.addedDate,
                        child: Text('Refinar por: Fecha añadido'),
                      ),
                      PopupMenuItem(
                        value: SortOption.brandAlphabetical,
                        child: Text('Refinar por: Marca (alfabético)'),
                      ),
                    ],
                  ),
                ]
              : null,
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: '🔎 Buscar por marca, modelo o placa...',
                  suffixIcon: IconButton(
                    icon: Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _searchTrucks('');
                    },
                  ),
                ),
                onChanged: _searchTrucks,
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredTrucks.length,
                itemBuilder: (context, index) {
                  final truck = _filteredTrucks[index];
                  return ListTile(
                    title: Text('${truck.brand} ${truck.model}'),
                    subtitle: Text(
                        'Año: ${truck.year}, Kilometraje: ${truck.mileage.toStringAsFixed(0)} Km'),
                    onTap: () => _showTruckDetails(context, truck),
                    trailing: widget.isAdmin
                        ? IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () =>
                                _confirmDeleteTruck(context, truck),
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

  void _showTruckDetails(BuildContext context, Truck truck) {
    bool showGenerateReportButton =
        truck.status == 'Requiere atención' && truck.wearLevel <= 1;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('${truck.brand} ${truck.model}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildField(context, 'Año', '${truck.year}'),
                _buildField(context, 'Kilometraje', '${truck.mileage} Km.'),
                _buildField(context, 'Placa', truck.plate),
                _buildField(context, 'Color', truck.color),
                _buildField(context, 'Estado', truck.status),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text('Salud general:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                SizedBox(
                  height: 100,
                  width: 100,
                  child: CustomPaint(
                    painter: WearLevelThermometer(wearLevel: truck.wearLevel),
                  ),
                ),
                _buildField(context, 'Comentarios', truck.comments),
                _buildField(context, 'Última actualización',
                    DateFormat('dd-MM-yyyy – kk:mm').format(truck.lastUpdated)),
                if (widget.isAdmin)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      _navigateAndDisplayEditScreen(context, truck);
                    },
                    child: Text('✏ Editar'),
                  ),
                if (showGenerateReportButton)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => _generateReport(truck),
                    child: Text('📋 Generar reporte'),
                  ),
              ],
            ),
          ),
          actions: <Widget>[
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

  Widget _buildField(
      BuildContext context, String fieldName, String fieldValue) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style,
          children: [
            TextSpan(
              text: '$fieldName: ',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: fieldValue),
          ],
        ),
      ),
    );
  }
}

class WearLevelThermometer extends CustomPainter {
  final double wearLevel;

  WearLevelThermometer({required this.wearLevel});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = min(centerX, centerY) - 10;
    final startAngle = -pi / 2;
    final sweepAngle = pi;
    final paint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 20
      ..style = PaintingStyle.stroke;

    canvas.drawArc(
        Rect.fromCircle(center: Offset(centerX, centerY), radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint);

    Color color;
    if (wearLevel <= 3.0) {
      color = Colors.red;
    } else if (wearLevel <= 6.0) {
      color = Colors.yellow;
    } else {
      color = Colors.green;
    }

    paint.color = color;

    final angle = wearLevel / 10 * pi;
    canvas.drawArc(
        Rect.fromCircle(center: Offset(centerX, centerY), radius: radius),
        startAngle,
        angle,
        false,
        paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class EditTruckScreen extends StatefulWidget {
  final Truck truck;

  EditTruckScreen({required this.truck});

  @override
  _EditTruckScreenState createState() => _EditTruckScreenState();
}

class _EditTruckScreenState extends State<EditTruckScreen> {
  final TextEditingController _mileageController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  final TextEditingController _wearLevelController = TextEditingController();
  final TextEditingController _commentsController = TextEditingController();
  String _selectedStatus = 'Operativo';
  int _selectedWearLevel = 1;

  @override
  void initState() {
    super.initState();
    _mileageController.text = widget.truck.mileage.toString();
    _colorController.text = widget.truck.color;
    _selectedStatus = widget.truck.status;
    _wearLevelController.text = widget.truck.wearLevel.toString();
    _selectedWearLevel = widget.truck.wearLevel.round().clamp(1, 10);
    _commentsController.text = widget.truck.comments;
  }

  void _updateTruckDetails() async {
    try {
      await FirebaseFirestore.instance
          .collection('trucks')
          .doc(widget.truck.id)
          .update({
        'mileage': double.parse(_mileageController.text),
        'color': _colorController.text,
        'status': _selectedStatus,
        'wearLevel': _selectedWearLevel.toDouble(),
        'comments': _commentsController.text,
        'lastUpdated': Timestamp.now(),
      });
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ Camión actualizado con éxito.")));
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Error al actualizar el camión: $error")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Editar camión'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _mileageController,
              decoration: InputDecoration(labelText: 'Kilometraje'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _colorController,
              decoration: InputDecoration(labelText: 'Color'),
            ),
            DropdownButton<String>(
              value: _selectedStatus,
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value!;
                });
              },
              items: <String>['Operativo', 'Inoperativo', 'Requiere atención']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            DropdownButton<int>(
              value: _selectedWearLevel,
              onChanged: (newValue) {
                setState(() {
                  _selectedWearLevel = newValue!;
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
            TextField(
              controller: _commentsController,
              decoration: InputDecoration(labelText: 'Comentarios'),
              maxLines: null,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              onPressed: _updateTruckDetails,
              child: Text('💾 Guardar cambios'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
