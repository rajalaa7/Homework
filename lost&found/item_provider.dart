import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/item_model.dart';

class ItemProvider with ChangeNotifier {
  List<LostFoundItem> _items = [];
  List<LostFoundItem> _filteredItems = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedType = 'All';

  List<LostFoundItem> get items => _filteredItems;
  bool get isLoading => _isLoading;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  ItemProvider() {
    fetchItems();
  }

  Future<void> fetchItems() async {
    _isLoading = true;
    notifyListeners();

    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('lost_found_items')
          .orderBy('dateReported', descending: true)
          .get();

      _items = snapshot.docs
          .map((doc) => LostFoundItem.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      _applyFilters();
    } catch (e) {
      print('Error fetching items: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<String?> uploadImage(File imageFile) async {
    try {
      final String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final Reference ref = _storage.ref().child('item_images/$fileName');
      final UploadTask uploadTask = ref.putFile(imageFile);
      final TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<bool> addItem(LostFoundItem item, File? imageFile) async {
    try {
      String? imageUrl;
      if (imageFile != null) {
        imageUrl = await uploadImage(imageFile);
      }

      final LostFoundItem newItem = LostFoundItem(
        id: item.id,
        title: item.title,
        description: item.description,
        category: item.category,
        location: item.location,
        contactInfo: item.contactInfo,
        type: item.type,
        imageUrl: imageUrl,
        dateReported: item.dateReported,
        reporterName: item.reporterName,
      );

      await _firestore
          .collection('lost_found_items')
          .doc(item.id)
          .set(newItem.toMap());

      _items.insert(0, newItem);
      _applyFilters();
      notifyListeners();
      return true;
    } catch (e) {
      print('Error adding item: $e');
      return false;
    }
  }

  Future<bool> markAsClaimed(String itemId) async {
    try {
      await _firestore
          .collection('lost_found_items')
          .doc(itemId)
          .update({'isClaimed': true});

      final index = _items.indexWhere((item) => item.id == itemId);
      if (index != -1) {
        _items[index] = LostFoundItem(
          id: _items[index].id,
          title: _items[index].title,
          description: _items[index].description,
          category: _items[index].category,
          location: _items[index].location,
          contactInfo: _items[index].contactInfo,
          type: _items[index].type,
          imageUrl: _items[index].imageUrl,
          dateReported: _items[index].dateReported,
          isClaimed: true,
          reporterName: _items[index].reporterName,
        );
        _applyFilters();
        notifyListeners();
      }
      return true;
    } catch (e) {
      print('Error marking item as claimed: $e');
      return false;
    }
  }

  void searchItems(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilters();
    notifyListeners();
  }

  void filterByCategory(String category) {
    _selectedCategory = category;
    _applyFilters();
    notifyListeners();
  }

  void filterByType(String type) {
    _selectedType = type;
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    _filteredItems = _items.where((item) {
      final matchesSearch = _searchQuery.isEmpty ||
          item.title.toLowerCase().contains(_searchQuery) ||
          item.description.toLowerCase().contains(_searchQuery) ||
          item.location.toLowerCase().contains(_searchQuery);

      final matchesCategory = _selectedCategory == 'All' ||
          item.category == _selectedCategory;

      final matchesType = _selectedType == 'All' ||
          item.type == _selectedType;

      return matchesSearch && matchesCategory && matchesType;
    }).toList();
  }
}