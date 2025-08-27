import 'package:flutter/material.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:odontologo/object/inventory_stock.dart';
import 'package:odontologo/services/inventory_stock_service.dart';
import 'package:odontologo/services/pdf_service.dart';
import 'package:odontologo/widgets/card_container.dart';
import 'package:intl/intl.dart';

class ReporteStockSuministros extends StatefulWidget {
  const ReporteStockSuministros({super.key});

  @override
  State<ReporteStockSuministros> createState() => _ReporteStockSuministrosState();
}

class _ReporteStockSuministrosState extends State<ReporteStockSuministros> {
  List<InventoryStock> _stockList = [];
  List<InventoryStock> _filteredStockList = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedCategory = '';
  String _selectedStatus = '';
  String _selectedLocation = '';

  // Controladores para filtros
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _statusController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadStockData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _categoryController.dispose();
    _statusController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _loadStockData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final stockData = await InventoryStockService.getInventoryStock();
      setState(() {
        _stockList = stockData;
        _filteredStockList = stockData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        AwesomeDialog(
          context: context,
          dialogType: DialogType.error,
          title: 'Error',
          desc: 'No se pudo cargar el stock: $e',
          btnOkText: 'Entendido',
          btnOkOnPress: () {},
        ).show();
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredStockList = _stockList.where((item) {
        bool matchesSearch = _searchQuery.isEmpty ||
            item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            item.code.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            item.batchNumber.toLowerCase().contains(_searchQuery.toLowerCase());

        bool matchesCategory = _selectedCategory.isEmpty ||
            item.category == _selectedCategory;

        bool matchesStatus = _selectedStatus.isEmpty ||
            item.stockStatus == _selectedStatus;

        bool matchesLocation = _selectedLocation.isEmpty ||
            item.warehouseLocation.toLowerCase().contains(_selectedLocation.toLowerCase());

        return matchesSearch && matchesCategory && matchesStatus && matchesLocation;
      }).toList();
    });
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _selectedCategory = '';
      _selectedStatus = '';
      _selectedLocation = '';
      _filteredStockList = _stockList;
    });
    
    _searchController.clear();
    _categoryController.clear();
    _statusController.clear();
    _locationController.clear();
  }

  Future<void> _generatePdfReport() async {
    if (_filteredStockList.isEmpty) {
      if (!mounted) return;
      AwesomeDialog(
        context: context,
        dialogType: DialogType.warning,
        title: 'Sin datos',
        desc: 'No hay datos para generar el reporte',
        btnOkText: 'Entendido',
        btnOkOnPress: () {},
      ).show();
      return;
    }

    try {
      final pdfBytes = await PdfService.generateStockReportPdf(_filteredStockList);
      
      if (mounted) {
        Navigator.pushNamed(
          context,
          '/pdf_viewer',
          arguments: {
            'pdfBytes': pdfBytes,
            'title': 'Reporte Stock Suministros',
          },
        );
      }
    } catch (e) {
      if (!mounted) return;
      AwesomeDialog(
        context: context,
        dialogType: DialogType.error,
        title: 'Error',
        desc: 'No se pudo generar el PDF: $e',
        btnOkText: 'Entendido',
        btnOkOnPress: () {},
      ).show();
    }
  }

  Map<String, dynamic> _getStatistics() {
    return InventoryStockService.getStockStatistics(_filteredStockList);
  }

  @override
  Widget build(BuildContext context) {
    final statistics = _getStatistics();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reporte Stock Suministros'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filtros
          _buildFiltersSection(),
          
          // Estadísticas
          _buildStatisticsSection(statistics),
          
          // Botones de acción
          _buildActionButtons(),
          
          // Lista de stock
          Expanded(
            child: _buildStockList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection() {
    return CardContainer(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filtros',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Buscar por nombre, código o lote',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      _searchQuery = value;
                      _applyFilters();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _categoryController,
                    decoration: const InputDecoration(
                      labelText: 'Categoría',
                      prefixIcon: Icon(Icons.category),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      _selectedCategory = value;
                      _applyFilters();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _statusController,
                    decoration: const InputDecoration(
                      labelText: 'Estado del stock',
                      prefixIcon: Icon(Icons.info),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      _selectedStatus = value;
                      _applyFilters();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      labelText: 'Ubicación',
                      prefixIcon: Icon(Icons.location_on),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      _selectedLocation = value;
                      _applyFilters();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: _clearFilters,
                  icon: const Icon(Icons.clear),
                  label: const Text('Limpiar Filtros'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsSection(Map<String, dynamic> statistics) {
    return CardContainer(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Estadísticas del Stock',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Items',
                    '${statistics['totalItems']}',
                    Icons.inventory,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Valor Total',
                    '\$${NumberFormat('#,##0.00').format(statistics['totalValue'])}',
                    Icons.attach_money,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Stock Bajo',
                    '${statistics['lowStockItems']}',
                    Icons.warning,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Items Expirados',
                    '${statistics['expiredItems']}',
                    Icons.error,
                    Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _loadStockData,
            icon: _isLoading 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            label: Text(_isLoading ? 'Cargando...' : 'Actualizar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
          ElevatedButton.icon(
            onPressed: _filteredStockList.isEmpty ? null : _generatePdfReport,
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Generar PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_filteredStockList.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No se encontraron items de stock',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredStockList.length,
      itemBuilder: (context, index) {
        final item = _filteredStockList[index];
        return _buildStockItem(item);
      },
    );
  }

  Widget _buildStockItem(InventoryStock item) {
    final availableQty = double.tryParse(item.availableQuantity) ?? 0.0;
    final isLowStock = availableQty <= item.minStock;
    final isExpired = _isItemExpired(item.expirationDate);
    
    Color statusColor = Colors.green;
    if (isExpired) {
      statusColor = Colors.red;
    } else if (isLowStock) {
      statusColor = Colors.orange;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Código: ${item.code} | Lote: ${item.batchNumber}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    item.stockStatus,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStockInfo('Disponible', item.availableQuantity, ''),
                ),
                Expanded(
                  child: _buildStockInfo('Reservado', item.reservedQuantity, ''),
                ),
                Expanded(
                  child: _buildStockInfo('Total', item.totalQuantity, ''),
                ),
                Expanded(
                  child: _buildStockInfo('Costo Prom.', '\$${item.averageCost}', ''),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStockInfo('Stock Mín.', '${item.minStock}', ''),
                ),
                Expanded(
                  child: _buildStockInfo('Stock Máx.', '${item.maxStock}', ''),
                ),
                Expanded(
                  child: _buildStockInfo('Ubicación', item.warehouseLocation, ''),
                ),
                Expanded(
                  child: _buildStockInfo('Vencimiento', _formatDate(item.expirationDate), ''),
                ),
              ],
            ),
            if (isLowStock || isExpired)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(
                      isExpired ? Icons.error : Icons.warning,
                      color: statusColor,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isExpired 
                          ? 'Item expirado'
                          : 'Stock bajo (${item.minStock})',
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockInfo(String label, String value, String unit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  bool _isItemExpired(String expirationDate) {
    if (expirationDate.isEmpty) return false;
    try {
      final expiration = DateTime.parse(expirationDate);
      return expiration.isBefore(DateTime.now());
    } catch (e) {
      return false;
    }
  }

  String _formatDate(String dateString) {
    if (dateString.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }
} 