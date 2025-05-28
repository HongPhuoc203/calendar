// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../../providers/event_provider.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:intl/intl.dart';
// import '../events/event_detail_screen.dart';

// class HomeScreen extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     final eventProvider = Provider.of<EventProvider>(context);

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('C Global Calendar'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.add),
//             tooltip: 'Thêm mới',
//             onPressed: () {
              
//               Navigator.pushNamed(context, '/add_event');

//             },
//           ),
//         ],
//       ),
//       drawer: Drawer(
//         child: ListView(
//           padding: EdgeInsets.zero,
//           children: [
//             DrawerHeader(
//               decoration: const BoxDecoration(
//                 gradient: LinearGradient(
//                   colors: [Colors.blue, Colors.purple],
//                 ),
//               ),
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Image.asset(
//                     'lib/Picture/cglobal.jpg',
//                     width: 64,
//                     height: 64,
//                   ),
//                   const SizedBox(height: 8),
//                   const Text(
//                     'C Global Calendar',
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     'Xin chào, ${FirebaseAuth.instance.currentUser?.email?.split('@').first ?? 'Người dùng'}',
//                     style: const TextStyle(
//                       color: Colors.white70,
//                       fontSize: 16,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             ListTile(
//               leading: const Icon(Icons.calendar_today),
//               title: const Text('Lịch sự kiện'),
//               onTap: () {
                
//                 Navigator.pushNamed(context, '/calendar');
//               },
//             ),
//             ListTile(
//               leading: const Icon(Icons.logout),
//               title: const Text('Đăng xuất'),
//               onTap: () async {
//                 await FirebaseAuth.instance.signOut();
//                 Navigator.pushReplacementNamed(context, '/login');
//               },
//             ),
//           ],
//         ),
//       ),
//       body: eventProvider.events.isEmpty
//           ? const Center(
//               child: Text(
//                 'Chưa có sự kiện nào!',
//                 style: TextStyle(fontSize: 18, color: Colors.grey),
//               ),
//             )
//           : ListView.builder(
//               itemCount: eventProvider.events.length,
//               itemBuilder: (context, index) {
//                 final event = eventProvider.events[index];
//                 return Card(
//                   margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                   elevation: 4,
//                   child: ListTile(
//                     leading: const Icon(Icons.event, color: Colors.blue),
//                     title: Text(event.title),
//                     subtitle: Text('${event.description}\n${DateFormat('dd/MM/yyyy').format(event.dateTime)}',),
//                     trailing: Text(
//                       DateFormat('HH:mm').format(event.dateTime),
//                       style: const TextStyle(fontWeight: FontWeight.bold),
//                     ),
//                     onTap: () {
//                       // TODO: Xem chi tiết sự kiện
//                       // Navigator.push(
//                       //   context,
//                       //   MaterialPageRoute(builder:(_) => EventDetailScreen(event: event)),
//                       // );
//                     },
//                   ),
//                 );
//               },
//             ),
//     );
//   }
// }