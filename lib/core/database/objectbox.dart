import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:remember_me_please/objectbox.g.dart';

class ObjectBox {
  /// The Store is your database engine connection.
  late final Store store;

  // A private constructor. We only want this class to be created via the create()
  // method and NOTE the _create name constructor is not related to the create()
  // method you can chose any name they must not be the same.
  ObjectBox._create(this.store);

  /// Constructor to allow setting up a specific Store for testing purposes.
  ObjectBox.fromStore(this.store);

  /// This is the setup function you will call ONE TIME in your main.dart
  static Future<ObjectBox> create() async {
    // Find a safe, private folder on the phone to store the database file
    final docsDir = await getApplicationDocumentsDirectory();
    debugPrint("📦 ObjectBox DB location: ${docsDir.path}");

    // Define the exact path (e.g., AppData/Documents/remember_me_db)
    final dbPath = p.join(docsDir.path, "remember_me_db");

    // Open the connection! (openStore is generated inside objectbox.g.dart)
    final store = await openStore(directory: dbPath);

    return ObjectBox._create(store);
  }
}
