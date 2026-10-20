import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class LocationPickResult {
  final String address;
  final String physicalLocation;
  final double latitude;
  final double longitude;

  const LocationPickResult({
    required this.address,
    required this.physicalLocation,
    required this.latitude,
    required this.longitude,
  });
}

class LocationPickerDialog extends StatefulWidget {
  final String? initialAddress;
  final String? initialPhysicalLocation;
  final double? initialLatitude;
  final double? initialLongitude;

  const LocationPickerDialog({
    super.key,
    this.initialAddress,
    this.initialPhysicalLocation,
    this.initialLatitude,
    this.initialLongitude,
  });

  @override
  State<LocationPickerDialog> createState() => _LocationPickerDialogState();
}

class _LocationPickerDialogState extends State<LocationPickerDialog> {
  late TextEditingController _addressController;
  late TextEditingController _indoorController;
  late LatLng _currentPoint;
  final MapController _mapController = MapController();

  // Danh sách các địa điểm mẫu trong khuôn viên đại học
  final List<Map<String, dynamic>> _presetLocations = [
    {
      'name': 'Thư viện Tạ Quang Bửu - ĐHBK Hà Nội',
      'lat': 21.0049,
      'lng': 105.8458,
    },
    {
      'name': 'Tòa nhà A2 - ĐH Kinh tế Quốc dân (NEU)',
      'lat': 20.9995,
      'lng': 105.8423,
    },
    {
      'name': 'Trung tâm Học liệu - ĐH Quốc Gia Hà Nội (VNU)',
      'lat': 21.0378,
      'lng': 105.7825,
    },
    {
      'name': 'Thư viện Trung tâm ĐHQG TP.HCM (Thủ Đức)',
      'lat': 10.8700,
      'lng': 106.8030,
    },
  ];

  @override
  void initState() {
    super.initState();
    _addressController = TextEditingController(
      text: widget.initialAddress ?? 'Thư viện Tạ Quang Bửu - ĐHBK Hà Nội',
    );
    _indoorController = TextEditingController(
      text: widget.initialPhysicalLocation ?? '',
    );
    _currentPoint = LatLng(
      widget.initialLatitude ?? 21.0049,
      widget.initialLongitude ?? 105.8458,
    );
  }

  @override
  void dispose() {
    _addressController.dispose();
    _indoorController.dispose();
    super.dispose();
  }

  void _onTapMap(TapPosition tapPosition, LatLng point) {
    setState(() {
      _currentPoint = point;
    });
  }

  void _selectPreset(Map<String, dynamic> preset) {
    final latLng = LatLng(preset['lat'] as double, preset['lng'] as double);
    setState(() {
      _currentPoint = latLng;
      _addressController.text = preset['name'] as String;
    });
    _mapController.move(latLng, 16.0);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 600;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: isDesktop ? 650 : double.infinity,
        height: 680,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3F51B5).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.add_location_alt_rounded, color: Color(0xFF3F51B5)),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chọn Vị Trí Lưu Trữ Sách/Tài Liệu',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Chạm trên bản đồ hoặc chọn điểm trường/thư viện',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Địa điểm gợi ý nhanh
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _presetLocations.map((p) {
                  final isSelected = _addressController.text == p['name'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        (p['name'] as String).split(' - ').first,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (_) => _selectPreset(p),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),

            // Bản đồ tương tác OpenStreetMap
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _currentPoint,
                        initialZoom: 15.0,
                        onTap: _onTapMap,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.studyhub.app',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _currentPoint,
                              width: 50,
                              height: 50,
                              child: const Icon(
                                Icons.location_on_rounded,
                                color: Colors.redAccent,
                                size: 44,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.65),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_currentPoint.latitude.toStringAsFixed(4)}, ${_currentPoint.longitude.toStringAsFixed(4)}',
                          style: const TextStyle(color: Colors.white, fontSize: 11),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Trường nhập Địa chỉ vĩ mô
            TextField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: 'Địa chỉ / Tòa nhà / Thư viện (Vĩ mô)',
                hintText: 'Vd: Thư viện Tạ Quang Bửu, ĐHBK Hà Nội',
                prefixIcon: const Icon(Icons.business_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 10),

            // Trường nhập Vị trí vi mô (Tủ, Ngăn, Kệ)
            TextField(
              controller: _indoorController,
              decoration: InputDecoration(
                labelText: 'Vị trí chi tiết trong phòng/nhà (Vi mô)',
                hintText: 'Vd: Tủ số 3, Kệ A2, Ngăn 2',
                prefixIcon: const Icon(Icons.shelves),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),

            // Nút Xác nhận
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3F51B5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.check_circle_rounded),
              label: const Text(
                'Lưu Vị Trí Tài Liệu Này',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              onPressed: () {
                final addr = _addressController.text.trim();
                final indoor = _indoorController.text.trim();
                Navigator.pop(
                  context,
                  LocationPickResult(
                    address: addr.isNotEmpty ? addr : 'Vị trí đã ghim',
                    physicalLocation: indoor.isNotEmpty ? indoor : 'Kệ sách tự do',
                    latitude: _currentPoint.latitude,
                    longitude: _currentPoint.longitude,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
