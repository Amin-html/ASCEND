import 'package:flutter/material.dart';

void main() => runApp(const CarShowroomApp());

class CarShowroomApp extends StatelessWidget {
  const CarShowroomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: const Scaffold(
        backgroundColor: Color(0xFF090A0D),
        // Магия: центрируем и жестко задаем ширину телефона (400px)
        body: Center(
          child: SizedBox(
            width: 400,
            child: CarCatalogScreen(),
          ),
        ),
      ),
    );
  }
}

class CarCatalogScreen extends StatefulWidget {
  const CarCatalogScreen({super.key});

  @override
  State<CarCatalogScreen> createState() => _CarCatalogScreenState();
}

class _CarCatalogScreenState extends State<CarCatalogScreen> {
  final List<Map<String, dynamic>> _cars = [
    {
      'name': 'Porsche Turbo S',
      'type': 'Спорткар',
      'price': '\$450',
      'power': '650 л.с.',
      'acceleration': '2.7 сек',
      'color': Colors.orangeAccent,
      'icon': Icons.bolt,
    },
    {
      'name': 'Tesla Model S Plaid',
      'type': 'Электро / Седан',
      'price': '\$350',
      'power': '1020 л.с.',
      'acceleration': '2.1 сек',
      'color': Colors.cyanAccent,
      'icon': Icons.electric_car,
    },
    {
      'name': 'Lamborghini Urus',
      'type': 'Премиум Кроссовер',
      'price': '\$600',
      'power': '666 л.с.',
      'acceleration': '3.5 сек',
      'color': Colors.redAccent,
      'icon': Icons.terrain,
    },
  ];

  int _selectedCarIndex = 0;

  void _bookCar(String carName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: _cars[_selectedCarIndex]['color'],
        duration: const Duration(seconds: 2),
        content: Text(
          '🎉 Успешно! $carName забронирован!',
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeCar = _cars[_selectedCarIndex];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Добро пожаловать 👋', style: TextStyle(color: Colors.white54, fontSize: 13)),
                  Text('Влад, выбери авто', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.notifications_none, color: Colors.white, size: 20),
              )
            ],
          ),
          const SizedBox(height: 25),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(16)),
            child: const Row(
              children: [
                Icon(Icons.search, color: Colors.white30, size: 18),
                SizedBox(width: 12),
                Text('Поиск суперкара вашей мечты...', style: TextStyle(color: Colors.white30, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 30),
          const Text('ТОПОВЫЕ ПРЕДЛОЖЕНИЯ', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 15),
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _cars.length,
              itemBuilder: (context, index) {
                bool isSelected = index == _selectedCarIndex;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCarIndex = index),
                  child: Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? _cars[index]['color'].withOpacity(0.15) : Colors.white10,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: isSelected ? _cars[index]['color'] : Colors.white10, width: 1.5),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_cars[index]['icon'], color: isSelected ? _cars[index]['color'] : Colors.white60, size: 24),
                        const SizedBox(height: 6),
                        Text(
                          _cars[index]['name'].split(' ')[0],
                          style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.white60, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 30),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(activeCar['type'], style: TextStyle(color: activeCar['color'], fontSize: 12, fontWeight: FontWeight.bold)),
                          Text('${activeCar['price']}/день', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(activeCar['name'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _specItem('МОЩНОСТЬ', activeCar['power'], Icons.bolt),
                      _specItem('0-100 КМ/Ч', activeCar['acceleration'], Icons.timer),
                    ],
                  ),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: activeCar['color'],
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => _bookCar(activeCar['name']),
                      child: const Text('АРЕНДОВАТЬ СЕЙЧАС', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _specItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white30, size: 22),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }
}