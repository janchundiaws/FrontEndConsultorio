# Archivo de Configuración - settings.json

Este archivo contiene la configuración centralizada de la aplicación, incluyendo tipos de transacción, opciones de estado y configuraciones generales.

## Estructura del Archivo

### 1. Tipos de Transacción (`transaction_types`)

#### Transacciones de Ingreso (`incoming`)
- **PURCHASE**: Compra de suministros a proveedores
- **DONATION**: Suministros recibidos como donación
- **RETURN**: Devolución de suministros por parte del cliente
- **ADJUSTMENT**: Ajuste de inventario por conteo físico
- **TRANSFER**: Transferencia desde otro almacén

#### Transacciones de Salida (`outgoing`)
- **SALE**: Venta de suministros a clientes
- **CONSUMPTION**: Consumo interno del consultorio
- **DAMAGED**: Suministros dañados o vencidos
- **TRANSFER_OUT**: Transferencia a otro almacén

### 2. Opciones de Estado (`status_options`)

#### Estados para Transacciones de Ingreso
- **PENDING**: Transacción pendiente de procesar
- **APPROVED**: Transacción aprobada y procesada
- **REJECTED**: Transacción rechazada
- **CANCELLED**: Transacción cancelada

#### Estados para Transacciones de Salida
- **PENDING**: Transacción pendiente de procesar
- **PROCESSED**: Transacción procesada y entregada
- **CANCELLED**: Transacción cancelada

### 3. Configuración de la Aplicación (`app_settings`)
- **default_currency**: Moneda por defecto
- **default_language**: Idioma por defecto
- **date_format**: Formato de fecha
- **decimal_places**: Número de decimales
- **pagination**: Configuración de paginación
- **timeout**: Timeouts para API y conexiones

## Cómo Modificar

### Agregar Nuevos Tipos de Transacción

1. Abre el archivo `settings.json`
2. Encuentra la sección `transaction_types.incoming` o `transaction_types.outgoing`
3. Agrega un nuevo objeto con la siguiente estructura:

```json
{
  "code": "NUEVO_TIPO",
  "name": "Nombre en Español",
  "description": "Descripción del tipo de transacción",
  "color": "#HEXCODE"
}
```

### Agregar Nuevos Estados

1. Encuentra la sección `status_options.incoming` o `status_options.outgoing`
2. Agrega un nuevo objeto con la siguiente estructura:

```json
{
  "code": "NUEVO_ESTADO",
  "name": "Nombre en Español",
  "description": "Descripción del estado",
  "color": "#HEXCODE"
}
```

### Modificar Colores

Los colores se definen en formato hexadecimal (#RRGGBB):
- **Verde**: #4CAF50
- **Azul**: #2196F3
- **Naranja**: #FF9800
- **Morado**: #9C27B0
- **Gris**: #607D8B
- **Rojo**: #F44336
- **Rosa**: #E91E63
- **Marrón**: #795548

## Beneficios de esta Configuración

1. **Centralización**: Todos los tipos y estados están en un solo lugar
2. **Flexibilidad**: Fácil de modificar sin tocar código
3. **Internacionalización**: Soporte para múltiples idiomas
4. **Personalización**: Colores y descripciones personalizables
5. **Mantenimiento**: Cambios se reflejan automáticamente en toda la app

## Uso en el Código

```dart
// Cargar tipos de transacción
final transactionTypes = await SettingsService.getIncomingTransactionTypes();

// Cargar opciones de estado
final statusOptions = await SettingsService.getIncomingStatusOptions();

// Obtener configuración de la app
final appSettings = await SettingsService.getAppSettings();
```

## Notas Importantes

- Después de modificar el archivo, reinicia la aplicación
- Los cambios se aplican automáticamente sin necesidad de recompilar
- El servicio incluye configuraciones por defecto como fallback
- Los datos se cachean para mejor rendimiento 