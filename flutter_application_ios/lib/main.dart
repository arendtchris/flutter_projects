import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:win_ble/win_ble.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Web API Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Web API Example'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;
  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  late Future<List<dynamic>> _dataFuture;
  StreamSubscription? scanStream;
  StreamSubscription? connectionStream;
  StreamSubscription? bleStateStream;
  bool isScanning = false;
  BleState bleState = BleState.Unknown;
  List<BleDevice> devices = <BleDevice>[];

  static Map<String, dynamic> ble_services = {
    "00001811-0000-1000-8000-00805f9b34fb": "Alert Notification Service",
    "0000180f-0000-1000-8000-00805f9b34fb": "Battery Service",
    "00001810-0000-1000-8000-00805f9b34fb": "Blood Pressure",
    "00001805-0000-1000-8000-00805f9b34fb": "Current Time Service",
    "00001818-0000-1000-8000-00805f9b34fb": "Cycling Power",
    "00001816-0000-1000-8000-00805f9b34fb": "Cycling Speed and Cadence",
    "0000180a-0000-1000-8000-00805f9b34fb": "Device Information",
    "00001800-0000-1000-8000-00805f9b34fb": "Generic Access",
    "00001801-0000-1000-8000-00805f9b34fb": "Generic Attribute",
    "00001808-0000-1000-8000-00805f9b34fb": "Glucose",
    "00001809-0000-1000-8000-00805f9b34fb": "Health Thermometer",
    "0000180d-0000-1000-8000-00805f9b34fb": "Heart Rate",
    "00001812-0000-1000-8000-00805f9b34fb": "Human Interface Device",
    "00001802-0000-1000-8000-00805f9b34fb": "Immediate Alert",
    "00001803-0000-1000-8000-00805f9b34fb": "Link Loss",
    "00001819-0000-1000-8000-00805f9b34fb": "Location and Navigation",
    "00001807-0000-1000-8000-00805f9b34fb": "Next DST Change Service",
    "0000180e-0000-1000-8000-00805f9b34fb": "Phone Alert Status Service",
    "00001806-0000-1000-8000-00805f9b34fb": "Reference Time Update Service",
    "00001814-0000-1000-8000-00805f9b34fb": "Running Speed and Cadence",
    "00001813-0000-1000-8000-00805f9b34fb": "Scan Parameters",
    "00001804-0000-1000-8000-00805f9b34fb": "Tx Power",
    "00002a43-0000-1000-8000-00805f9b34fb": "Alert Category ID",
    "00002a42-0000-1000-8000-00805f9b34fb": "Alert Category ID Bit Mask",
    "00002a06-0000-1000-8000-00805f9b34fb": "Alert Level",
    "00002a44-0000-1000-8000-00805f9b34fb": "Alert Notification Control Point",
    "00002a3f-0000-1000-8000-00805f9b34fb": "Alert Status",
    "00002a01-0000-1000-8000-00805f9b34fb": "Appearance",
    "00002a19-0000-1000-8000-00805f9b34fb": "Battery Level",
    "00002a49-0000-1000-8000-00805f9b34fb": "Blood Pressure Feature",
    "00002a35-0000-1000-8000-00805f9b34fb": "Blood Pressure Measurement",
    "00002a38-0000-1000-8000-00805f9b34fb": "Body Sensor Location",
    "00002a22-0000-1000-8000-00805f9b34fb": "Boot Keyboard Input Report",
    "00002a32-0000-1000-8000-00805f9b34fb": "Boot Keyboard Output Report",
    "00002a33-0000-1000-8000-00805f9b34fb": "Boot Mouse Input Report",
    "00002a5c-0000-1000-8000-00805f9b34fb": "CSC Feature",
    "00002a5b-0000-1000-8000-00805f9b34fb": "CSC Measurement",
    "00002a2b-0000-1000-8000-00805f9b34fb": "Current Time",
    "00002a66-0000-1000-8000-00805f9b34fb": "Cycling Power Control Point",
    "00002a65-0000-1000-8000-00805f9b34fb": "Cycling Power Feature",
    "00002a63-0000-1000-8000-00805f9b34fb": "Cycling Power Measurement",
    "00002a64-0000-1000-8000-00805f9b34fb": "Cycling Power Vector",
    "00002a08-0000-1000-8000-00805f9b34fb": "Date Time",
    "00002a0a-0000-1000-8000-00805f9b34fb": "Day Date Time",
    "00002a09-0000-1000-8000-00805f9b34fb": "Day of Week",
    "00002a00-0000-1000-8000-00805f9b34fb": "Device Name",
    "00002a0d-0000-1000-8000-00805f9b34fb": "DST Offset",
    "00002a0c-0000-1000-8000-00805f9b34fb": "Exact Time 256",
    "00002a26-0000-1000-8000-00805f9b34fb": "Firmware Revision String",
    "00002a51-0000-1000-8000-00805f9b34fb": "Glucose Feature",
    "00002a18-0000-1000-8000-00805f9b34fb": "Glucose Measurement",
    "00002a34-0000-1000-8000-00805f9b34fb": "Glucose Measurement Context",
    "00002a27-0000-1000-8000-00805f9b34fb": "Hardware Revision String",
    "00002a39-0000-1000-8000-00805f9b34fb": "Heart Rate Control Point",
    "00002a37-0000-1000-8000-00805f9b34fb": "Heart Rate Measurement",
    "00002a4c-0000-1000-8000-00805f9b34fb": "HID Control Point",
    "00002a4a-0000-1000-8000-00805f9b34fb": "HID Information",
    "00002a2a-0000-1000-8000-00805f9b34fb":
        "IEEE 11073-20601 Regulatory Certification Data List",
    "00002a36-0000-1000-8000-00805f9b34fb": "Intermediate Cuff Pressure",
    "00002a1e-0000-1000-8000-00805f9b34fb": "Intermediate Temperature",
    "00002a6b-0000-1000-8000-00805f9b34fb": "LN Control Point",
    "00002a6a-0000-1000-8000-00805f9b34fb": "LN Feature",
    "00002a0f-0000-1000-8000-00805f9b34fb": "Local Time Information",
    "00002a67-0000-1000-8000-00805f9b34fb": "Location and Speed",
    "00002a29-0000-1000-8000-00805f9b34fb": "Manufacturer Name String",
    "00002a21-0000-1000-8000-00805f9b34fb": "Measurement Interval",
    "00002a24-0000-1000-8000-00805f9b34fb": "Model Number String",
    "00002a68-0000-1000-8000-00805f9b34fb": "Navigation",
    "00002a46-0000-1000-8000-00805f9b34fb": "New Alert",
    "00002a04-0000-1000-8000-00805f9b34fb":
        "Peripheral Preferred Connection Parameters",
    "00002a02-0000-1000-8000-00805f9b34fb": "Peripheral Privacy Flag",
    "00002a50-0000-1000-8000-00805f9b34fb": "PnP ID",
    "00002a69-0000-1000-8000-00805f9b34fb": "Position Quality",
    "00002a4e-0000-1000-8000-00805f9b34fb": "Protocol Mode",
    "00002a03-0000-1000-8000-00805f9b34fb": "Reconnection Address",
    "00002a52-0000-1000-8000-00805f9b34fb": "Record Access Control Point",
    "00002a14-0000-1000-8000-00805f9b34fb": "Reference Time Information",
    "00002a4d-0000-1000-8000-00805f9b34fb": "Report",
    "00002a4b-0000-1000-8000-00805f9b34fb": "Report Map",
    "00002a40-0000-1000-8000-00805f9b34fb": "Ringer Control Point",
    "00002a41-0000-1000-8000-00805f9b34fb": "Ringer Setting",
    "00002a54-0000-1000-8000-00805f9b34fb": "RSC Feature",
    "00002a53-0000-1000-8000-00805f9b34fb": "RSC Measurement",
    "00002a55-0000-1000-8000-00805f9b34fb": "SC Control Point",
    "00002a4f-0000-1000-8000-00805f9b34fb": "Scan Interval Window",
    "00002a31-0000-1000-8000-00805f9b34fb": "Scan Refresh",
    "00002a5d-0000-1000-8000-00805f9b34fb": "Sensor Location",
    "00002a25-0000-1000-8000-00805f9b34fb": "Serial Number String",
    "00002a05-0000-1000-8000-00805f9b34fb": "Service Changed",
    "00002a28-0000-1000-8000-00805f9b34fb": "Software Revision String",
    "00002a47-0000-1000-8000-00805f9b34fb": "Supported New Alert Category",
    "00002a48-0000-1000-8000-00805f9b34fb": "Supported Unread Alert Category",
    "00002a23-0000-1000-8000-00805f9b34fb": "System ID",
    "00002a1c-0000-1000-8000-00805f9b34fb": "Temperature Measurement",
    "00002a1d-0000-1000-8000-00805f9b34fb": "Temperature Type",
    "00002a12-0000-1000-8000-00805f9b34fb": "Time Accuracy",
    "00002a13-0000-1000-8000-00805f9b34fb": "Time Source",
    "00002a16-0000-1000-8000-00805f9b34fb": "Time Update Control Point",
    "00002a17-0000-1000-8000-00805f9b34fb": "Time Update State",
    "00002a11-0000-1000-8000-00805f9b34fb": "Time with DST",
    "00002a0e-0000-1000-8000-00805f9b34fb": "Time Zone",
    "00002a07-0000-1000-8000-00805f9b34fb": "Tx Power Level",
    "00002a45-0000-1000-8000-00805f9b34fb": "Unread Alert Status"
  };

  @override
  void initState() {
    WinBle.initialize(enableLog: false);

    // Listen to Ble State Stream
    bleStateStream = WinBle.bleState.listen((BleState state) {
      setState(() {
        bleState = state;
        print(bleState);
      });
    });

    connectionStream = WinBle.connectionStream.listen((event) {
      print("Connection Event : " + event.toString());
    });

    scanStream = WinBle.scanStream.listen((event) {
      setState(() {
        if (!devices.any((element) => element.address == event.address)) {
          devices.add(event);
          print(event.address);
        }
      });
    });

    _dataFuture = fetchDataFromApi();

    super.initState();
  }

  @override
  void dispose() {
    scanStream?.cancel();
    connectionStream?.cancel();
    bleStateStream?.cancel();

    WinBle.dispose();
    super.dispose();
  }

  toggleScanning() {
    if (!isScanning) {
      print("start scanning");

      WinBle.startScanning();
      setState(() {
        isScanning = true;
      });
    } else {
      print("stop scanning");

      WinBle.stopScanning();
      setState(() {
        isScanning = false;
      });

      connectDevice();
    }
  }

  connectDevice() async {
    for (var dev in devices) {
      try {
        await WinBle.connect(dev.address);

        bool canPair = await WinBle.canPair(dev.address);
        bool isPaired = await WinBle.isPaired(dev.address);
        var services = await WinBle.discoverServices(dev.address);

        for (var id in services) {
          print(ble_services[id]);
          List<BleCharacteristic> bleCharacteristics =
              await WinBle.discoverCharacteristics(
                  address: dev.address, serviceId: id);
          for (var blec in bleCharacteristics) {
            print(blec.toJson());
          }
        }
      } catch (error_) {
        print('Ble_error: $error_');
      }
    }
    // WinBle.connect( );
  }

  /// Determine the current position of the device.
  ///
  /// When the location services are not enabled or permissions
  /// are denied the `Future` will return an error.
  Future<List<dynamic>> fetchDataFromApi() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.requestPermission();

    if (permission == LocationPermission.denied) {
      return Future.error('Location permissions are denied');
    } else if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied.');
    }

    Position position = await Geolocator.getCurrentPosition();

    List<dynamic> data = [
      {'title': 'GeoData longitude', 'description': '${position.longitude}'},
      {'title': 'GeoData latitude', 'description': '${position.latitude}'},
    ];

    Uri url = Uri.parse(
        'https://geocode.xyz/${position.latitude},${position.longitude}?geoit=json&auth=426393451072149252633x82975');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final Map jsonData = json.decode(response.body);

      jsonData.forEach((key, value) {
        if (value is Map) {
        } else {
          data.add({'title': key, 'description': value});
        }
      });

      return data;
    } else {
      throw Exception('Failed to load data from API');
    }
  }

  Widget showWebData(
      BuildContext context, AsyncSnapshot<List<dynamic>> snapshot) {
    if (snapshot.hasData) {
      final data = snapshot.data!;
      return ListView.builder(
        itemCount: data.length,
        itemBuilder: (context, index) {
          final item = data[index];
          return ListTile(
            leading: const Icon(
              Icons.add_location_rounded,
              color: Colors.blue,
              size: 36.0,
            ),
            title: Text(item['title']),
            subtitle: Text(item['description']),
          );
        },
      );
    } else if (snapshot.hasError) {
      return Text('Error: ${snapshot.error}');
    } else {
      return const CircularProgressIndicator();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: bleState == BleState.On
            ? const Text('bluetooth On')
            : const Text('bluetooth Off'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: toggleScanning,
        child: const Text('scan'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _dataFuture,
        builder: showWebData,
      ),
    );
  }
}
