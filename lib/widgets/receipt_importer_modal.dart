import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../models/grocery_item.dart';
import '../services/openrouter_service.dart';
import 'tactile_tap.dart';

class ReceiptImporterModal extends StatefulWidget {
  final List<GroceryItem> inventory;
  final Function(List<GroceryItem> matchedItems) onImportItems;

  const ReceiptImporterModal({
    super.key,
    required this.inventory,
    required this.onImportItems,
  });

  @override
  State<ReceiptImporterModal> createState() => _ReceiptImporterModalState();
}

class _ReceiptImporterModalState extends State<ReceiptImporterModal> {
  final TextEditingController _rawTextController = TextEditingController(
    text: '''D-MART STORE RECEIPT #4819
Masala Oats 500g - 1
Maggi 2-Minute Noodles 560g - 2
Basmati Rice 5kg - 1
Jeera Whole 250g - 1
Toor Dal Premium 1kg - 2
Mustard Oil 1L - 1
Paneer Fresh 200g - 2
Amul Butter 100g - 1''',
  );

  final ImagePicker _picker = ImagePicker();
  Uint8List? _capturedImageBytes;
  bool _isAnalyzing = false;
  List<GroceryItem> _matchedItems = [];
  bool _hasAnalyzed = false;

  ItemCategory _inferCategory(String name, [String? categoryKey]) {
    if (categoryKey != null && categoryKey.isNotEmpty) {
      switch (categoryKey) {
        case 'readyToCook':
          return ItemCategory.readyToCook;
        case 'singleSpices':
          return ItemCategory.singleSpices;
        case 'masalaBlends':
          return ItemCategory.masalaBlends;
        case 'freshProduce':
          return ItemCategory.freshProduce;
        case 'riceGrains':
          return ItemCategory.riceGrains;
        case 'pulsesLentils':
          return ItemCategory.pulsesLentils;
        case 'dryFruitsNuts':
          return ItemCategory.dryFruitsNuts;
        case 'floursBaking':
          return ItemCategory.floursBaking;
        case 'kitchenStaples':
          return ItemCategory.kitchenStaples;
      }
    }

    final lower = name.toLowerCase();
    if (lower.contains('oats') ||
        lower.contains('maggi') ||
        lower.contains('maggie') ||
        lower.contains('noodle') ||
        lower.contains('pasta') ||
        lower.contains('soup') ||
        lower.contains('ready') ||
        lower.contains('mix') ||
        lower.contains('cereal')) {
      return ItemCategory.readyToCook;
    }
    if (lower.contains('garam masala') ||
        lower.contains('sambhar') ||
        lower.contains('pav bhaji') ||
        lower.contains('biryani masala') ||
        lower.contains('chaat') ||
        lower.contains('chana masala') ||
        lower.contains('kitchen king')) {
      return ItemCategory.masalaBlends;
    }
    if (lower.contains('jeera') ||
        lower.contains('haldi') ||
        lower.contains('mirch') ||
        lower.contains('turmeric') ||
        lower.contains('cumin') ||
        lower.contains('mustard') ||
        lower.contains('rai') ||
        lower.contains('cardamom') ||
        lower.contains('cinnamon') ||
        lower.contains('pepper') ||
        lower.contains('clove')) {
      return ItemCategory.singleSpices;
    }
    if (lower.contains('rice') ||
        lower.contains('basmati') ||
        lower.contains('poha') ||
        lower.contains('quinoa') ||
        lower.contains('millet')) {
      return ItemCategory.riceGrains;
    }
    if (lower.contains('dal') ||
        lower.contains('toor') ||
        lower.contains('moong') ||
        lower.contains('chana') ||
        lower.contains('rajma') ||
        lower.contains('urad') ||
        lower.contains('masoor') ||
        lower.contains('pulse') ||
        lower.contains('lentil')) {
      return ItemCategory.pulsesLentils;
    }
    if (lower.contains('atta') ||
        lower.contains('besan') ||
        lower.contains('maida') ||
        lower.contains('sooji') ||
        lower.contains('rava') ||
        lower.contains('flour') ||
        lower.contains('baking')) {
      return ItemCategory.floursBaking;
    }
    if (lower.contains('almond') ||
        lower.contains('badam') ||
        lower.contains('cashew') ||
        lower.contains('kaju') ||
        lower.contains('walnut') ||
        lower.contains('pista') ||
        lower.contains('raisin') ||
        lower.contains('kishmish') ||
        lower.contains('nut')) {
      return ItemCategory.dryFruitsNuts;
    }
    if (lower.contains('tomato') ||
        lower.contains('onion') ||
        lower.contains('potato') ||
        lower.contains('ginger') ||
        lower.contains('garlic') ||
        lower.contains('coriander') ||
        lower.contains('lemon') ||
        lower.contains('chilli')) {
      return ItemCategory.freshProduce;
    }

    return ItemCategory.kitchenStaples;
  }

  Map<String, dynamic> _extractWeightAndQty(String rawText) {
    String cleanName = rawText;
    String detectedUnit = '1 kg';
    int detectedQty = 1;

    // Check quantity at end (e.g. "- 2" or "x 2" or "Qty: 2" or "2 Pcs")
    final qtyMatch = RegExp(r'[-–xX\s]+(\d+)\s*(?:pcs|pc|qty|packs|pack)?\s*$', caseSensitive: false).firstMatch(cleanName);
    if (qtyMatch != null && qtyMatch.group(1) != null) {
      final parsed = int.tryParse(qtyMatch.group(1)!);
      if (parsed != null && parsed > 0) {
        detectedQty = parsed;
      }
      cleanName = cleanName.substring(0, qtyMatch.start).trim();
    }

    // Check weight unit (e.g. "560g", "560 g", "500g", "1.5kg", "250g", "1L", "500ml", "1kg")
    final weightMatch = RegExp(r'(\d+(?:\.\d+)?)\s*(kg|g|gm|gms|l|ltr|liter|litres|ml|pack|pcs|pc|bunch)\b', caseSensitive: false).firstMatch(cleanName);
    if (weightMatch != null) {
      final numStr = weightMatch.group(1)!;
      final rawUnitStr = weightMatch.group(2)!.toLowerCase();
      String normUnit = rawUnitStr;
      if (rawUnitStr == 'gm' || rawUnitStr == 'gms') normUnit = 'g';
      if (rawUnitStr == 'ltr' || rawUnitStr == 'liter' || rawUnitStr == 'litres') normUnit = 'L';
      if (rawUnitStr == 'l') normUnit = 'L';
      if (rawUnitStr == 'pc' || rawUnitStr == 'pcs') normUnit = 'Pc';
      if (rawUnitStr == 'pack') normUnit = 'Pack';

      detectedUnit = '$numStr $normUnit'.trim();
      cleanName = cleanName.replaceAll(weightMatch.group(0)!, '').trim();
    }

    cleanName = cleanName.replaceAll(RegExp(r'^[-\s\u2022]+|[-\s\u2022]+$'), '').trim();

    return {
      'name': cleanName.isEmpty ? rawText : cleanName,
      'unit': detectedUnit,
      'quantity': detectedQty,
    };
  }

  Future<void> _captureImage(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        imageQuality: 90,
        maxWidth: 1600,
      );

      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() {
          _capturedImageBytes = bytes;
          _isAnalyzing = true;
          _hasAnalyzed = false;
          _matchedItems = [];
        });

        // Analyze via OpenRouter AI Vision (Gemini-2.0 Flash)
        final scannedItems = await OpenRouterService.analyzeReceiptImage(bytes);

        if (mounted) {
          _matchScannedReceiptItems(scannedItems);
          setState(() {
            _isAnalyzing = false;
            _hasAnalyzed = true;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
            content: Text(
              'Could not access camera or gallery permissions.',
              style: TextStyle(fontSize: 13, color: Colors.white),
            ),
          ),
        );
      }
    }
  }

  void _matchScannedReceiptItems(List<ScannedReceiptItem> scannedItems) {
    final matches = <GroceryItem>[];

    for (var scanned in scannedItems) {
      final lower = scanned.name.toLowerCase().trim();
      if (lower.isEmpty) continue;

      final inferredCategory = _inferCategory(scanned.name, scanned.categoryKey);
      final unitsList = [scanned.unit, '1 kg', '500 g', '250 g', '1 Pack', '1 L', '100 g'].toSet().toList();

      final found = widget.inventory.firstWhere(
        (i) =>
            i.nameEn.toLowerCase() == lower ||
            i.nameEn.toLowerCase().contains(lower) ||
            lower.contains(i.nameEn.toLowerCase()),
        orElse: () => GroceryItem(
          id: 'scanned_${DateTime.now().millisecondsSinceEpoch}_${scanned.name.hashCode}',
          nameEn: scanned.name,
          nameHi: scanned.name,
          category: inferredCategory,
          availableUnits: unitsList,
          selectedUnit: scanned.unit,
          quantity: scanned.quantity > 0 ? scanned.quantity : 1,
          isAdded: true,
        ),
      );

      final updated = found.copyWith(
        category: found.category == ItemCategory.kitchenStaples ? inferredCategory : found.category,
        selectedUnit: scanned.unit.isNotEmpty ? scanned.unit : found.selectedUnit,
        availableUnits: [scanned.unit, ...found.availableUnits].toSet().toList(),
        quantity: scanned.quantity > 0 ? scanned.quantity : found.quantity,
        isAdded: true,
      );

      matches.add(updated);
    }

    setState(() {
      _matchedItems = matches;
    });
  }

  void _analyzeTextBill() {
    final rawText = _rawTextController.text;
    final lines = rawText.split('\n');
    final extractedItems = <ScannedReceiptItem>[];

    for (var line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty ||
          trimmed.toUpperCase().contains('RECEIPT') ||
          trimmed.toUpperCase().contains('STORE') ||
          trimmed.toUpperCase().contains('TOTAL') ||
          trimmed.toUpperCase().contains('TAX')) continue;

      final parsed = _extractWeightAndQty(trimmed);
      final name = parsed['name'] as String;
      final unit = parsed['unit'] as String;
      final qty = parsed['quantity'] as int;

      if (name.length > 1) {
        extractedItems.add(
          ScannedReceiptItem(
            name: name,
            quantity: qty,
            unit: unit,
            categoryKey: _inferCategory(name).name,
          ),
        );
      }
    }

    _matchScannedReceiptItems(extractedItems);

    setState(() {
      _hasAnalyzed = true;
    });
  }

  void _removeItemFromMatched(int index) {
    setState(() {
      _matchedItems.removeAt(index);
    });
  }

  // ==========================================
  // USER FIX / EDIT MODAL (Full User Control)
  // ==========================================
  void _editScannedItem(int index) {
    final item = _matchedItems[index];
    final nameCtrl = TextEditingController(text: item.nameEn);
    final unitCtrl = TextEditingController(text: item.selectedUnit);
    ItemCategory selectedCategory = item.category;
    int quantity = item.quantity;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              left: 20,
              right: 20,
              top: 14,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: AppColors.borderDark,
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Edit Scanned Item',
                      style: AppTypography.displaySmall(fontSize: 17),
                    ),
                    IconButton(
                      iconSize: 20,
                      icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 1. Item Name
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                  decoration: const InputDecoration(
                    labelText: 'Item Name',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: AppRadii.mdBorder),
                  ),
                ),
                const SizedBox(height: 14),

                // 2. Category Selector Chips
                Text('Category:', style: AppTypography.label()),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: ItemCategory.values.where((c) => c != ItemCategory.all).map((cat) {
                    final isSel = selectedCategory == cat;
                    return TactileTap(
                      onTap: () => setModalState(() => selectedCategory = cat),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: isSel ? AppColors.primaryLight : AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSel ? AppColors.primary : AppColors.border,
                            width: isSel ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(cat.icon, size: 13, color: isSel ? AppColors.primaryDark : AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              cat.label,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                                color: isSel ? AppColors.primaryDark : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                // 3. Weight / Unit Quick Chips + Custom Text
                Text('Weight / Unit:', style: AppTypography.label()),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: unitCtrl,
                        style: const TextStyle(fontSize: 13),
                        decoration: const InputDecoration(
                          hintText: 'e.g. 500 g, 560 g, 1 kg',
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(borderRadius: AppRadii.mdBorder),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Quick unit options
                    ...['500 g', '560 g', '1 kg', '250 g', '1 Pack'].map((u) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: TactileTap(
                          onTap: () {
                            setModalState(() {
                              unitCtrl.text = u;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                            decoration: BoxDecoration(
                              color: unitCtrl.text == u ? AppColors.primaryLight : AppColors.surfaceMuted,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: unitCtrl.text == u ? AppColors.primary : AppColors.border),
                            ),
                            child: Text(
                              u,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: unitCtrl.text == u ? AppColors.primaryDark : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 14),

                // 4. Quantity Stepper
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Quantity:', style: AppTypography.label()),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          TactileTap(
                            onTap: () {
                              if (quantity > 1) {
                                setModalState(() => quantity--);
                              }
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              child: Icon(Icons.remove_rounded, size: 16, color: AppColors.textPrimary),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              '$quantity',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                            ),
                          ),
                          TactileTap(
                            onTap: () => setModalState(() => quantity++),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              child: Icon(Icons.add_rounded, size: 16, color: AppColors.textPrimary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Save Changes Button
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: TactileTap(
                    onTap: () {
                      final updatedName = nameCtrl.text.trim().isEmpty ? item.nameEn : nameCtrl.text.trim();
                      final updatedUnit = unitCtrl.text.trim().isEmpty ? item.selectedUnit : unitCtrl.text.trim();

                      setState(() {
                        _matchedItems[index] = item.copyWith(
                          nameEn: updatedName,
                          nameHi: updatedName,
                          category: selectedCategory,
                          selectedUnit: updatedUnit,
                          availableUnits: [updatedUnit, ...item.availableUnits].toSet().toList(),
                          quantity: quantity,
                        );
                      });

                      Navigator.pop(ctx);
                    },
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: AppShadows.soft,
                      ),
                      child: const Text(
                        'SAVE ITEM CHANGES',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAddManualItemDialog() {
    final nameCtrl = TextEditingController();
    final unitCtrl = TextEditingController(text: '1 kg');
    ItemCategory selectedCategory = ItemCategory.readyToCook;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.xlBorder),
          title: Text(
            'Add Item to Receipt List',
            style: AppTypography.displaySmall(fontSize: 18),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  autofocus: true,
                  style: const TextStyle(fontSize: 13.5),
                  decoration: const InputDecoration(
                    labelText: 'Item Name',
                    hintText: 'e.g. Masala Oats, Maggi, Paneer',
                    border: OutlineInputBorder(borderRadius: AppRadii.mdBorder),
                  ),
                  onChanged: (val) {
                    setDlgState(() {
                      selectedCategory = _inferCategory(val);
                    });
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: unitCtrl,
                  style: const TextStyle(fontSize: 13.5),
                  decoration: const InputDecoration(
                    labelText: 'Unit / Weight',
                    hintText: 'e.g. 500 g, 560 g, 1 kg, 1 Pack',
                    border: OutlineInputBorder(borderRadius: AppRadii.mdBorder),
                  ),
                ),
                const SizedBox(height: 12),
                Text('Category:', style: AppTypography.label()),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: ItemCategory.values.where((c) => c != ItemCategory.all).map((cat) {
                    final isSel = selectedCategory == cat;
                    return InkWell(
                      onTap: () => setDlgState(() => selectedCategory = cat),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSel ? AppColors.primaryLight : AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: isSel ? AppColors.primary : AppColors.border),
                        ),
                        child: Text(
                          cat.label,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                            color: isSel ? AppColors.primaryDark : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: const RoundedRectangleBorder(borderRadius: AppRadii.mdBorder),
              ),
              onPressed: () {
                final name = nameCtrl.text.trim();
                final unit = unitCtrl.text.trim().isEmpty ? '1 kg' : unitCtrl.text.trim();
                if (name.isNotEmpty) {
                  final newItem = ScannedReceiptItem(
                    name: name,
                    unit: unit,
                    quantity: 1,
                    categoryKey: selectedCategory.name,
                  );
                  _matchScannedReceiptItems([
                    newItem,
                    ..._matchedItems.map((i) => ScannedReceiptItem(
                          name: i.nameEn,
                          unit: i.selectedUnit,
                          quantity: i.quantity,
                          categoryKey: i.category.name,
                        ))
                  ]);
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Add Item', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _rawTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 14,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: const BoxDecoration(
                  color: AppColors.borderDark,
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Title Row with Dismiss
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.accentBlue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.receipt_long_rounded, color: AppColors.accentBlue, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Receipt & Bill Scanner',
                        style: AppTypography.displaySmall(fontSize: 18),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'Tap any item to correct name, category or weight',
                        style: AppTypography.bodySmall(),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  iconSize: 20,
                  icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // CAMERA & GALLERY SCANNER ACTION BUTTONS (Tactile Spring)
            Row(
              children: [
                Expanded(
                  child: TactileTap(
                    onTap: () => _captureImage(ImageSource.camera),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.accentBlue,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: AppShadows.soft,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'CAMERA SCAN',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TactileTap(
                    onTap: () => _captureImage(ImageSource.gallery),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.accentBlue, width: 1.5),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.photo_library_rounded, color: AppColors.accentBlue, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'GALLERY PHOTO',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accentBlue,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // CAMERA CAPTURED PHOTO PREVIEW & RESCAN BAR
            if (_capturedImageBytes != null) ...[
              Stack(
                children: [
                  Container(
                    height: 130,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.accentBlue, width: 1.5),
                      image: DecorationImage(
                        image: MemoryImage(_capturedImageBytes!),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: _isAnalyzing
                        ? Container(
                            color: Colors.black.withValues(alpha: 0.65),
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                  SizedBox(height: 8),
                                  Text(
                                    'AI Vision reading items...',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : null,
                  ),
                  if (!_isAnalyzing)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Row(
                        children: [
                          TactileTap(
                            onTap: () => _captureImage(ImageSource.camera),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.75),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.refresh_rounded, color: Colors.white, size: 14),
                                  SizedBox(width: 4),
                                  Text(
                                    'Rescan',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
            ],

            // TEXT PASTE INPUT OPTION
            if (_capturedImageBytes == null) ...[
              TextField(
                controller: _rawTextController,
                maxLines: 4,
                style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Paste store bill text here...',
                  filled: true,
                  fillColor: AppColors.background,
                  contentPadding: EdgeInsets.all(12),
                  border: OutlineInputBorder(
                    borderRadius: AppRadii.mdBorder,
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppRadii.mdBorder,
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TactileTap(
                  onTap: _analyzeTextBill,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.textPrimary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.analytics_rounded, size: 15, color: Colors.white),
                        SizedBox(width: 6),
                        Text(
                          'Parse Text Bill',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],

            // MATCHED ITEMS RESULT LIST (With Direct Tap to Edit & Delete)
            if (_hasAnalyzed) ...[
              if (_matchedItems.isEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.warningLight,
                    borderRadius: AppRadii.lgBorder,
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.receipt_long_rounded, color: AppColors.warningDark, size: 30),
                      const SizedBox(height: 8),
                      const Text(
                        'No items clearly recognized',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF92400E)),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Ensure the photo is clear and well lit, or paste the text above.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, color: Color(0xFFB45309)),
                      ),
                      const SizedBox(height: 10),
                      TactileTap(
                        onTap: () => _captureImage(ImageSource.camera),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: AppColors.warningDark,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Retake Photo',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'MATCHED ITEMS (${_matchedItems.length} Found):',
                      style: AppTypography.label(letterSpacing: 0.8),
                    ),
                    TactileTap(
                      onTap: _showAddManualItemDialog,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_rounded, size: 14, color: AppColors.primaryDark),
                            SizedBox(width: 3),
                            Text(
                              'Add Item',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                Container(
                  constraints: const BoxConstraints(maxHeight: 220),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: AppRadii.lgBorder,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(6),
                    shrinkWrap: true,
                    itemCount: _matchedItems.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
                    itemBuilder: (context, index) {
                      final item = _matchedItems[index];

                      return InkWell(
                        onTap: () => _editScannedItem(index),
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(item.category.icon, color: AppColors.primary, size: 16),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.nameEn,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                          decoration: BoxDecoration(
                                            color: AppColors.surface,
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: AppColors.border),
                                          ),
                                          child: Text(
                                            item.category.label,
                                            style: const TextStyle(
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryLight,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            '${item.selectedUnit} x ${item.quantity}',
                                            style: const TextStyle(
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.primaryDark,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // Edit indicator
                              IconButton(
                                iconSize: 16,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary),
                                tooltip: 'Edit item',
                                onPressed: () => _editScannedItem(index),
                              ),
                              const SizedBox(width: 10),
                              // Delete button
                              IconButton(
                                iconSize: 18,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: const Icon(Icons.close_rounded, color: AppColors.danger),
                                tooltip: 'Remove item',
                                onPressed: () => _removeItemFromMatched(index),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: TactileTap(
                    onTap: () {
                      widget.onImportItems(_matchedItems);
                      Navigator.of(context).pop();

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: AppColors.primary,
                          behavior: SnackBarBehavior.floating,
                          content: Text(
                            'Successfully added ${_matchedItems.length} items to your inventory!',
                            style: const TextStyle(fontSize: 13, color: Colors.white),
                          ),
                        ),
                      );
                    },
                    child: Container(
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: AppRadii.mdBorder,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_shopping_cart_rounded, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'IMPORT ${_matchedItems.length} ITEMS TO INVENTORY',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
