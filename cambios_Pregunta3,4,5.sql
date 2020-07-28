--Pregunta 4
USE master
GO
ALTER DATABASE G4Lab2DB
ADD FILEGROUP G4Lab2DB_FG_nuevo;
GO
ALTER DATABASE G4Lab2DB
ADD FILE
(
    NAME = 'G4Lab2DB_FG2_nuevo',
    FILENAME = 'C:\MSSQL_DBS\G4Lab2DB\Data\G4Lab2DB_nuevo.ndf',
    SIZE = 5MB,
    MAXSIZE = 10MB,
    FILEGROWTH = 10%
)
TO FILEGROUP G4Lab2DB_FG_nuevo;
GO

--Pregunta 5


USE G4Lab2DB
GO
create schema inventario;
GO
CREATE TABLE inventario.[TotalArticulos]
(
 [idarticulo] Int NOT NULL,
 [totalpedidos] INT NOT NULL
) ON G4Lab2DB_FG_nuevo;
go
ALTER TABLE inventario.[TotalArticulos] ADD CONSTRAINT [PK_TotalArticulos] PRIMARY KEY ([idarticulo])
go
ALTER TABLE inventario.[TotalArticulos] ADD CONSTRAINT [se asocia a] FOREIGN KEY ([idarticulo]) REFERENCES dbo.[catalogo.Producto] ([numero_producto]) ON UPDATE CASCADE ON DELETE CASCADE
go

--Trigger inserción

CREATE TRIGGER trg_insert_pedido_detalle 
ON dbo.[movimientos.DetallePedido] 
AFTER INSERT 
AS 
BEGIN 

DECLARE @numero_producto INT;
DECLARE @cantidad INT;

SELECT @numero_producto = ins.numero_producto FROM INSERTED ins;
SELECT @cantidad = ins.cantidad FROM INSERTED ins;


IF EXISTS(SELECT * FROM inventario.[TotalArticulos] AS ti WHERE ti.idarticulo=@numero_producto)
	BEGIN
		UPDATE inventario.[TotalArticulos] SET totalpedidos = totalpedidos + @cantidad WHERE idarticulo=@numero_producto
	END
ELSE
	BEGIN
		INSERT INTO inventario.[TotalArticulos](idarticulo, totalpedidos) VALUES(@numero_producto, @cantidad)
	END
  

END 

GO


--Trigger Actualización

CREATE TRIGGER trg_update_pedido_detalle 
ON dbo.[movimientos.DetallePedido] 
AFTER UPDATE 
AS 
BEGIN 

DECLARE @numero_producto INT;
DECLARE @cantidad_anterior INT;
DECLARE @cantidad INT;

SELECT @numero_producto = ins.numero_producto FROM INSERTED ins;
SELECT @cantidad_anterior = del.cantidad FROM DELETED del;
SELECT @cantidad = ins.cantidad FROM INSERTED ins;


IF EXISTS(SELECT * FROM inventario.[TotalArticulos] AS ti WHERE ti.idarticulo=@numero_producto)
	BEGIN
		UPDATE inventario.[TotalArticulos] SET totalpedidos = totalpedidos + (@cantidad - @cantidad_anterior) WHERE idarticulo=@numero_producto
	END
ELSE
	BEGIN
		INSERT INTO inventario.[TotalArticulos](idarticulo, totalpedidos) VALUES(@numero_producto, @cantidad - @cantidad_anterior)
	END
END 

--Trigger Eliminación
GO

CREATE TRIGGER trg_delete_pedido_detalle 
ON dbo.[movimientos.DetallePedido] 
AFTER DELETE 
AS 
BEGIN 

DECLARE @numero_producto INT;
DECLARE @cantidad_anterior INT;

SELECT @numero_producto = del.numero_producto FROM DELETED del;
SELECT @cantidad_anterior = del.cantidad FROM DELETED del;


IF EXISTS(SELECT * FROM inventario.[TotalArticulos] AS ti WHERE ti.idarticulo=@numero_producto)
	BEGIN
		UPDATE inventario.[TotalArticulos] SET totalpedidos = totalpedidos - @cantidad_anterior WHERE idarticulo=@numero_producto
	END
ELSE
	BEGIN
		INSERT INTO inventario.[TotalArticulos](idarticulo, totalpedidos) VALUES(@numero_producto, @cantidad_anterior)
	END
END 

GO
