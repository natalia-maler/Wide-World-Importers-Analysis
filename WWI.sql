USE WideWorldImporters
GO

-- Sprzeda¿ - Sales
SELECT * FROM Sales.Customers
SELECT * FROM Sales.Orders
SELECT * FROM Sales.OrderLines
SELECT * FROM Sales.Invoices
SELECT * FROM Sales.InvoiceLines

-- Warehouse, Tutaj znajdziesz: produkty, ruch magazynowy, temperatury magazynu, historiê zmian stanów.
SELECT * FROM Warehouse.StockItems
SELECT * FROM Warehouse.StockItemTransactions
SELECT * FROM Warehouse.VehicleTemperatures
SELECT * FROM Warehouse.ColdRoomTemperatures

-- Purchasing - zakupy: dostawcy, zamówienia do dostawców, pozycje zamówieñ.
SELECT * FROM Purchasing.Suppliers
SELECT * FROM Purchasing.SupplierCategories
SELECT * FROM Purchasing.PurchaseOrders
SELECT * FROM Purchasing.PurchaseOrderLines
SELECT * FROM Purchasing.SupplierTransactions

-- Application - Pracownicy.
SELECT * FROM Application.People
SELECT * FROM Application.Cities
SELECT * FROM Application.StateProvinces
SELECT * FROM Application.Countries


/*--------------------------------*/
-- Purchasing - zakupy: dostawcy, zamówienia do dostawców, pozycje zamówieñ.
SELECT * FROM Purchasing.Suppliers
SELECT * FROM Purchasing.SupplierCategories
SELECT * FROM Purchasing.PurchaseOrders
SELECT * FROM Purchasing.PurchaseOrderLines
SELECT * FROM Purchasing.SupplierTransactions

-- Dostawcy z terminem p³atnoœci d³u¿szym ni¿ 14 dni
SELECT 
	SupplierName,
	PaymentDays
FROM Purchasing.Suppliers
WHERE PaymentDays > 14;

-- Liczba dostawców w poszczególnych kategoriach
SELECT
	sc.SupplierCategoryName,
	COUNT(*) AS LiczbaDostawcow -- TotalSuppliers, CountSuppliers
FROM Purchasing.Suppliers s
JOIN Purchasing.SupplierCategories sc ON s.SupplierCategoryID = sc.SupplierCategoryID
GROUP BY sc.SupplierCategoryName

-- Liczba zamówieñ ka¿dego dostawcy
SELECT
	s.SupplierName,
	COUNT(po.PurchaseOrderID) AS LiczbaZamowien
FROM Purchasing.PurchaseOrders po
JOIN Purchasing.Suppliers s ON po.SupplierID = s.SupplierID
GROUP BY s.SupplierName
ORDER BY LiczbaZamowien DESC;

-- Zamówienia oczekuj¹ce na dostawê
SELECT
    PurchaseOrderID,
    OrderDate,
    ExpectedDeliveryDate
FROM Purchasing.PurchaseOrders
WHERE ExpectedDeliveryDate > GETDATE();

-- Œredni czas oczekiwania na dostawê
SELECT
	AVG(DATEDIFF(Day, OrderDate, ExpectedDeliveryDate)) AS SredniCzasDostawy
FROM Purchasing.PurchaseOrders;

-- Najczêœciej zamawiane produkty pod wzglêdem ilosci opakowan
SELECT
	StockItemID,
	SUM(OrderedOuters) AS Zamowiono
FROM Purchasing.PurchaseOrderLines
GROUP BY StockItemID
ORDER BY Zamowiono DESC;

-- Produkty odebrane w mniejszej iloœci ni¿ zamówiono
SELECT
	PurchaseOrderID,
	StockItemID,
	OrderedOuters,
	ReceivedOuters
FROM Purchasing.PurchaseOrderLines
WHERE ReceivedOuters < OrderedOuters;

-- Wartoœæ zamówienia
SELECT
	PurchaseOrderID,
	SUM(OrderedOuters * ExpectedUnitPricePerOuter) AS WartoscZamowienia
FROM Purchasing.PurchaseOrderLines
GROUP BY PurchaseOrderID;

-- analiza jednego zamowienia
SELECT * FROM Purchasing.PurchaseOrderLines
SELECT
	PurchaseOrderID,
	SUM(ReceivedOuters) AS Otrzymano£¹cznie, -- czyli samu wysztkich sztuk: 18 + 21+18 = 57
	SUM(OrderedOuters * ExpectedUnitPricePerOuter) AS WartoscZamowienia
FROM Purchasing.PurchaseOrderLines
WHERE PurchaseOrderID = 1
GROUP BY PurchaseOrderID

-- £¹czna wartoœæ zakupów
SELECT
	SUM(TransactionAmount) AS LacznaWartoscZakupow
FROM Purchasing.SupplierTransactions;

-- Najwiêksze faktury
SELECT TOP 10
	SupplierInvoiceNumber,
	TransactionAmount
FROM Purchasing.SupplierTransactions
ORDER BY TransactionAmount DESC;


-- sposób dostawy
SELECT * FROM Application.DeliveryMethods
SELECT * FROM Application.TransactionTypes -- transationTypeID - tu jest
SELECT * FROM Application.PaymentMethods

-- Liczba zamowien wg metody dostawy
SELECT
    dm.DeliveryMethodName,
    COUNT(*) AS LiczbaZamowien
FROM Purchasing.PurchaseOrders po
JOIN Application.DeliveryMethods dm
ON po.DeliveryMethodID = dm.DeliveryMethodID
GROUP BY dm.DeliveryMethodName;

-- Liczba transakcji wg typu transakcji
SELECT
    tt.TransactionTypeName,
    COUNT(*) AS LiczbaTransakcji
FROM Purchasing.SupplierTransactions st
JOIN Application.TransactionTypes tt
ON st.TransactionTypeID = tt.TransactionTypeID
GROUP BY tt.TransactionTypeName;

-- Ilosc platnosci wg metody platnosci
SELECT
    pm.PaymentMethodName,
    COUNT(*) AS LiczbaPlatnosci
FROM Purchasing.SupplierTransactions st
JOIN Application.PaymentMethods pm
ON st.PaymentMethodID = pm.PaymentMethodID
GROUP BY pm.PaymentMethodName;



SELECT * FROM Application.People -- pozniej bedzie wyjasnione

-- Przyk³ady bardziej zaawansowanych zapytañ

-- Dostawca o najwiêkszej wartoœci zakupów - podzapytanie
SELECT SupplierName
FROM Purchasing.Suppliers
WHERE SupplierID = 
(
	SELECT TOP 1 SupplierID
	FROM Purchasing.SupplierTransactions
	GROUP BY SupplierID
	ORDER BY SUM(TransactionAmount) DESC
);

-- JOIN
SELECT TOP  1 SupplierName, SUM(TransactionAmount) AS TotalValue
FROM Purchasing.Suppliers s 
JOIN Purchasing.SupplierTransactions st ON s.SupplierID = st.SupplierID
GROUP BY s.SupplierName
ORDER BY TotalValue DESC;

SELECT TOP  1  SUM(TransactionAmount) AS TotalValue
FROM Purchasing.Suppliers s 
JOIN Purchasing.SupplierTransactions st ON s.SupplierID = st.SupplierID
GROUP BY s.SupplierName
ORDER BY TotalValue DESC;

-- Zamówienia o wartoœci wiêkszej od œredniej
SELECT 
PurchaseOrderID,
SUM(OrderedOuters * ExpectedUnitPricePerOuter) AS Wartosc
FROM Purchasing.PurchaseOrderLines
GROUP BY PurchaseOrderID
HAVING SUM(OrderedOuters * ExpectedUnitPricePerOuter) > 
(
	SELECT AVG(Wartosc)
	FROM
	(
		SELECT 
		SUM(OrderedOuters * ExpectedUnitPricePerOuter) AS Wartosc
		FROM Purchasing.PurchaseOrderLines
		GROUP BY PurchaseOrderID
	) AS T
);

-- Ranking dostawców wed³ug wartoœci zakupów (funkcja okna)
SELECT
s.SupplierName,
SUM(st.TransactionAmount) AS WartoscZakupow,
RANK() OVER(ORDER BY SUM(st.TransactionAmount) DESC) AS Ranking
FROM Purchasing.SupplierTransactions st
JOIN Purchasing.Suppliers s ON st.SupplierID = s.SupplierID
GROUP BY s.SupplierName;

-- Dostawcy, którzy maj¹ wiêcej zamówieñ ni¿ œrednia (CTE)
WITH Zamowienia AS
(
	SELECT SupplierID, COUNT(*) AS Liczba
	FROM Purchasing.PurchaseOrders
	GROUP BY SupplierID
)

SELECT
	s.SupplierName,
	z.Liczba
FROM Zamowienia z
JOIN Purchasing.Suppliers s ON s.SupplierID = z.SupplierID
WHERE z.Liczba >
( 
SELECT AVG(Liczba)
FROM Zamowienia
);

-- Terminowoœæ dostaw - moze wyjasnic
SELECT 
	po.PurchaseOrderID,
	po.OrderDate,
	po.ExpectedDeliveryDate,
	MAX(pol.LastReceiptDate) AS DataPrzyjecia,
	DATEDIFF(
	DAY,
	po.ExpectedDeliveryDate,
	MAX(pol.LastReceiptDate) 
	) AS Opoznienie
FROM Purchasing.PurchaseOrders po
JOIN Purchasing.PurchaseOrderLines pol ON po.PurchaseOrderID = pol.PurchaseOrderID
GROUP BY
po.PurchaseOrderID,
po.OrderDate,
po.ExpectedDeliveryDate;

-- Warehouse, Tutaj znajdziesz: produkty, ruch magazynowy, temperatury magazynu, historiê zmian stanów.
SELECT * FROM Warehouse.StockItems
SELECT * FROM Warehouse.StockItemTransactions
SELECT * FROM Warehouse.VehicleTemperatures
SELECT * FROM Warehouse.ColdRoomTemperatures

SELECT * FROM Warehouse.PackageTypes;
SELECT * FROM Application.TransactionTypes; -- TransactionTypeID

-- Produkty wymagaj¹ce ch³odni
SELECT
	StockItemID,
	StockItemName,
	UnitPrice
FROM Warehouse.StockItems
WHERE IsChillerStock = 1;

-- Produkty o najwy¿szej cenie
SELECT TOP 10
	StockItemName,
	UnitPrice
FROM Warehouse.StockItems
ORDER BY UnitPrice DESC;

-- Œrednia cena produktów
SELECT
AVG(UnitPrice) AS SredniaCena
FROM Warehouse.StockItems;

-- Œrednia masa produktów
SELECT
AVG(TypicalWeightPerUnit) AS SredniaWaga
FROM Warehouse.StockItems;

-- Dostawcy posiadaj¹cy najwiêcej produktów -- ? jakich produktów: czy rodzai czy ilosc zamowien
SELECT
	s.SupplierName,
	COUNT(si.StockItemID) AS LiczbaProduktow
FROM Warehouse.StockItems si
JOIN Purchasing.Suppliers s ON si.SupplierID = s.SupplierID
GROUP BY s.SupplierName
ORDER BY LiczbaProduktow DESC;

-- Produkty dro¿sze od œredniej ceny, sredniaCena = 44.15
SELECT
	StockItemName,
	UnitPrice
FROM Warehouse.StockItems
WHERE UnitPrice > 
(
	SELECT AVG(UnitPrice)
	FROM Warehouse.StockItems
);

-- Ranking najdro¿szych produktów, ilosc rodzai produktow = 227
SELECT
    StockItemName,
    UnitPrice,
    RANK() OVER(ORDER BY UnitPrice DESC) AS Ranking
FROM Warehouse.StockItems;

-- Produkty najczêœciej wydawane z magazynu, czyli na '-'
SELECT * FROM Warehouse.StockItemTransactions
SELECT
	sit.StockItemID,
	si.StockItemName,
	SUM(ABS(Quantity)) AS Ilosc
FROM Warehouse.StockItemTransactions sit
JOIN Warehouse.StockItems si ON sit.StockItemID = si.StockItemID
WHERE Quantity < 0
GROUP BY sit.StockItemID, si.StockItemName
ORDER BY Ilosc DESC;

-- Produkty najczêœciej przyjmowane do magazynu
SELECT
	sit.StockItemID,
	si.StockItemName,
	SUM(Quantity) AS Ilosc
FROM Warehouse.StockItemTransactions sit
JOIN Warehouse.StockItems si ON sit.StockItemID = si.StockItemID
WHERE Quantity > 0
GROUP BY sit.StockItemID, si.StockItemName
ORDER BY Ilosc DESC;

-- Bilans magazynowy produktów - to samo co powyzej
SELECT
	si.StockItemName,
	SUM(st.Quantity) AS StanMagazynowy
FROM Warehouse.StockItemTransactions st
JOIN Warehouse.StockItems si ON st.StockItemID = si.StockItemID
GROUP BY si.StockItemName
ORDER BY StanMagazynowy DESC;

-- Liczba operacji magazynowych dla produktów
SELECT
	si.StockItemName,
	COUNT(*) AS LiczbaOperacji
FROM Warehouse.StockItemTransactions st
JOIN Warehouse.StockItems si ON st.StockItemID = si.StockItemID
GROUP BY si.StockItemName
ORDER BY LiczbaOperacji DESC;

-- Najaktywniejsze dni w magazynie
SELECT
	CAST(TransactionOccurredWhen AS DATE) AS Data,
	COUNT(*) AS LiczbaOperacji
FROM Warehouse.StockItemTransactions
GROUP BY CAST(TransactionOccurredWhen AS DATE)
ORDER BY LiczbaOperacji DESC;

-- Œrednia temperatura w pojezdzie
SELECT * FROM Warehouse.VehicleTemperatures
SELECT
	VehicleRegistration,
	AVG(Temperature) AS SredniaTemperatura
FROM Warehouse.VehicleTemperatures
GROUP BY VehicleRegistration;

SELECT
    VehicleRegistration,
    MAX(Temperature) AS MaksymalnaTemperatura
FROM Warehouse.VehicleTemperatures
GROUP BY VehicleRegistration;

-- Œrednia temperatura ka¿dej ch³odni
SELECT
    ColdRoomSensorNumber,
    AVG(Temperature) AS SredniaTemperatura
FROM Warehouse.ColdRoomTemperatures
GROUP BY ColdRoomSensorNumber;

-- Produkty wraz z opakowaniem jednostkowym
SELECT
	si.StockItemName,
	pt.PackageTypeName
FROM Warehouse.StockItems si
JOIN Warehouse.PackageTypes pt ON si.UnitPackageID = pt.PackageTypeID;

-- Produkty wraz z opakowaniem zbiorczym
SELECT
    si.StockItemName,
    pt.PackageTypeName
FROM Warehouse.StockItems si
JOIN Warehouse.PackageTypes pt ON si.OuterPackageID = pt.PackageTypeID;

-- Liczba operacji wed³ug rodzaju transakcji
SELECT
	tt.TransactionTypeName,
	COUNT(*) AS LiczbaOperacji
FROM Warehouse.StockItemTransactions st
JOIN Application.TransactionTypes tt ON st.TransactionTypeID = tt.TransactionTypeID
GROUP BY tt.TransactionTypeName; 

-- £¹czna iloœæ produktów dla ka¿dego rodzaju transakcji
SELECT
	tt.TransactionTypeName,
	SUM(st.Quantity) AS IloscProduktow
FROM Warehouse.StockItemTransactions st
JOIN Application.TransactionTypes tt ON st.TransactionTypeID = tt.TransactionTypeID
GROUP BY tt.TransactionTypeName;

/* Dostawy + Magazyn */
-- Produkty dostarczane przez poszczególnych dostawców. Analiza pozwala okreœliæ asortyment oferowany przez poszczególnych dostawców.
SELECT
	s.SupplierName,
	si.StockItemName
FROM Warehouse.StockItems si
JOIN Purchasing.Suppliers s ON si.SupplierID = s.SupplierID
ORDER BY s.SupplierName, si.StockItemName;

-- Liczba produktów oferowanych przez ka¿dego dostawcê. Identyfikacja dostawców posiadaj¹cych najszersz¹ ofertê.
SELECT
	s.SupplierName,
	COUNT(si.StockItemID) AS LiczbaProduktow
FROM Purchasing.Suppliers s
JOIN Warehouse.StockItems si ON s.SupplierID = si.SupplierID
GROUP BY s.SupplierName
ORDER BY LiczbaProduktow DESC;

-- Zamówienia wraz z nazwami produktów. Analiza pokazuje, jakie produkty znalaz³y siê w konkretnych zamówieniach oraz ile opakowañ zamówiono i odebrano.
SELECT
	po.PurchaseOrderID,
	s.SupplierName,
	si.StockItemName,
	pol.OrderedOuters,
	pol.ReceivedOuters
FROM Purchasing.PurchaseOrders po
JOIN Purchasing.Suppliers s ON po.SupplierID = s.SupplierID
JOIN Purchasing.PurchaseOrderLines pol ON po.PurchaseOrderID = pol.PurchaseOrderID
JOIN Warehouse.StockItems si ON pol.StockItemID = si.StockItemID;

-- Produkty, których nie dostarczono w ca³oœci. Wykrywanie niekompletnych dostaw.
SELECT
	po.PurchaseOrderID,
	s.SupplierName,
	si.StockItemName,
	pol.OrderedOuters,
	pol.ReceivedOuters,
	(pol.OrderedOuters - pol.ReceivedOuters) AS BrakujaceOpakowania
FROM Purchasing.PurchaseOrders po
JOIN Purchasing.Suppliers s ON po.SupplierID = s.SupplierID
JOIN Purchasing.PurchaseOrderLines pol ON po.PurchaseOrderID = pol.PurchaseOrderID
JOIN Warehouse.StockItems si ON pol.StockItemID = si.StockItemID
WHERE pol.ReceivedOuters < pol.OrderedOuters;


-- tu tylko dostawy
-- Wartoœæ zamówieñ wed³ug dostawców. Analiza okreœla, od których dostawców firma dokonuje najwiêkszych zakupów.
SELECT 
	s.SupplierName,
	SUM(pol.OrderedOuters * pol.ExpectedUnitPricePerOuter) AS WartoscZakupow
FROM Purchasing.PurchaseOrders po
JOIN Purchasing.PurchaseOrderLines pol ON po.PurchaseOrderID = pol.PurchaseOrderID
JOIN Purchasing.Suppliers s ON po.SupplierID = s.SupplierID
GROUP BY s.SupplierName
ORDER BY WartoscZakupow DESC;

-- Œredni czas realizacji dostawy dla ka¿dego dostawcy. Analiza pokazuje, którzy dostawcy realizuj¹ zamówienia najszybciej.
SELECT
	s.SupplierName,
	AVG(DATEDIFF(DAY, po.OrderDate,pol.LastReceiptDate)) AS SredniCzasOczekiwania
FROM Purchasing.PurchaseOrders po
JOIN Purchasing.PurchaseOrderLines pol ON po.PurchaseOrderID = pol.PurchaseOrderID
JOIN Purchasing.Suppliers s ON po.SupplierID = s.SupplierID
GROUP BY s.SupplierName
ORDER BY SredniCzasOczekiwania;

-- Ranking produktów o najwiêkszej wartoœci zakupów. Analiza wskazuje produkty generuj¹ce najwiêksze koszty zakupów.
SELECT
    si.StockItemName,
    SUM(pol.OrderedOuters * pol.ExpectedUnitPricePerOuter) AS WartoscZakupu,
    RANK() OVER(
        ORDER BY SUM(pol.OrderedOuters * pol.ExpectedUnitPricePerOuter) DESC
    ) AS Ranking
FROM Purchasing.PurchaseOrderLines pol
JOIN Warehouse.StockItems si ON pol.StockItemID = si.StockItemID
GROUP BY si.StockItemName;

-- Produkty dostawców z czasem dostawy d³u¿szym od œredniej podzapytanie. Analiza identyfikuje produkty wymagaj¹ce d³u¿szego czasu oczekiwania od przeciêtnego.
SELECT
	s.SupplierName,
	si.StockItemName,
	si.LeadTimeDays
FROM Warehouse.StockItems si
JOIN Purchasing.Suppliers s ON si.SupplierID = s.SupplierID
WHERE si.LeadTimeDays > (
	SELECT AVG(LeadTimeDays)
	FROM Warehouse.StockItems

);

-- Dostawcy posiadaj¹cy wiêcej produktów ni¿ œrednia - CTE. Pokazanie dostawców z ofert¹ wiêksz¹ ni¿ przeciêtna.
WITH ProduktyDostawcow AS
(
	SELECT
		SupplierID,
		COUNT(*) AS LiczbaProduktow
	FROM Warehouse.StockItems
	GROUP BY SupplierID
)
SELECT
	s.SupplierName,
	p.LiczbaProduktow
FROM ProduktyDostawcow p
JOIN Purchasing.Suppliers s ON p.SupplierID = s.SupplierID
WHERE p.LiczbaProduktow > 
(
	SELECT AVG(LiczbaProduktow)
	FROM ProduktyDostawcow
);

-- œrednia liczba produktów przypadaj¹ca na dostawcê - podzapytanie
SELECT
      AVG(LiczbaProduktow) AS SredniaLiczbaProduktow
FROM 
(
	SELECT	
		SupplierID,
		COUNT(*) AS LiczbaProduktow
	FROM Warehouse.StockItems
	GROUP BY SupplierID
) AS Srednia;

-- sposób 2)
WITH ProduktyDostawcow AS
(
    SELECT
        SupplierID,
        COUNT(*) AS LiczbaProduktow
    FROM Warehouse.StockItems
    GROUP BY SupplierID
)
SELECT
    SupplierID,
    LiczbaProduktow,
    (SELECT AVG(LiczbaProduktow) FROM ProduktyDostawcow) AS Srednia
FROM ProduktyDostawcow;

-- Kompleksowa analiza procesu zakupu
SELECT
    po.PurchaseOrderID,
    s.SupplierName,
    si.StockItemName,
    po.OrderDate,
    po.ExpectedDeliveryDate,
    pol.LastReceiptDate,
    pol.OrderedOuters,
    pol.ReceivedOuters,
    pol.ExpectedUnitPricePerOuter,
    pol.OrderedOuters * pol.ExpectedUnitPricePerOuter AS WartoscPozycji,
    DATEDIFF(
        DAY,
        po.ExpectedDeliveryDate,
        pol.LastReceiptDate
    ) AS Opoznienie
FROM Purchasing.PurchaseOrders po
JOIN Purchasing.PurchaseOrderLines pol ON po.PurchaseOrderID = pol.PurchaseOrderID
JOIN Purchasing.Suppliers s ON po.SupplierID = s.SupplierID
JOIN Warehouse.StockItems si ON pol.StockItemID = si.StockItemID
ORDER BY po.PurchaseOrderID;

-- Sprzeda¿ - Sales
SELECT * FROM Sales.Customers
SELECT * FROM Sales.Orders
SELECT * FROM Sales.OrderLines
SELECT * FROM Sales.Invoices
SELECT * FROM Sales.InvoiceLines

-- Ilu jest klientów?
SELECT
COUNT(*) AS LiczbaKlientow
FROM Sales.Customers;

-- Klienci posiadaj¹cy limit kredytowy
SELECT
	CustomerName,
	CreditLimit
FROM Sales.Customers
WHERE CreditLimit IS NOT NULL;

-- Liczba zamówieñ
SELECT
	COUNT(*) AS LiczbaZamowien
FROM Sales.Orders;

-- Zamówienia klientów
SELECT
	c.CustomerName,
	o.OrderID,
	o.OrderDate
FROM Sales.Orders o
JOIN Sales.Customers c ON o.CustomerID=c.CustomerID;

-- Najczêœciej zamawiane produkty
SELECT
	StockItemID,
	SUM(Quantity) AS Ilosc
FROM Sales.OrderLines
GROUP BY StockItemID
ORDER BY Ilosc DESC;

-- Produkty nieskompletowane
SELECT
	OrderID,
	StockItemID,
	Quantity,
	PickedQuantity
FROM Sales.OrderLines
WHERE Quantity<>PickedQuantity;

-- Liczba faktur
SELECT
	COUNT(*) AS LiczbaFaktur
FROM Sales.Invoices;

-- Faktury wraz z klientami
SELECT
	c.CustomerName,
	i.InvoiceID,
	i.InvoiceDate
FROM Sales.Invoices i
JOIN Sales.Customers c ON i.CustomerID = c.CustomerID;

-- Najlepsi klienci
SELECT
	c.CustomerName,
	SUM(il.ExtendedPrice) AS Sprzedaz
FROM Sales.Customers c
JOIN Sales.Invoices i ON c.CustomerID = i.CustomerID
JOIN Sales.InvoiceLines il ON i.InvoiceID = il.InvoiceID
GROUP BY c.CustomerName
ORDER BY Sprzedaz DESC;

-- Najczêœciej kupowane produkty
SELECT
	si.StockItemName,
	SUM(il.Quantity) AS Sprzedano
FROM Sales.InvoiceLines il
JOIN Warehouse.StockItems si ON il.StockItemID = si.StockItemID
GROUP BY si.StockItemName
ORDER BY Sprzedano DESC;

-- Najbardziej dochodowe produkty
SELECT
	si.StockItemName,
	SUM(il.LineProfit) AS Zysk
FROM Sales.InvoiceLines il
JOIN Warehouse.StockItems si ON il.StockItemID = si.StockItemID
GROUP BY si.StockItemName
ORDER BY Zysk DESC;

-- Œrednia wartoœæ faktury
SELECT
	AVG(WartoscFaktury) AS SredniaFaktura
FROM 
(
	SELECT
		InvoiceID,
		SUM(ExtendedPrice) AS WartoscFaktury
	FROM Sales.InvoiceLines
	GROUP BY InvoiceID
)t;

-- Klienci kupuj¹cy wiêcej ni¿ œrednia
WITH SprzedazKlienta AS
(
	SELECT
	CustomerID,
	SUM(ExtendedPrice) AS Sprzedaz
	FROM Sales.Invoices i
	JOIN Sales.InvoiceLines il ON i.InvoiceID=il.InvoiceID 
	GROUP BY CustomerID
)

SELECT
	c.CustomerName,
	s.Sprzedaz
	FROM SprzedazKlienta s
	JOIN Sales.Customers c ON s.CustomerID=c.CustomerID
WHERE s.Sprzedaz>
(
	SELECT AVG(Sprzedaz)
	FROM SprzedazKlienta
);

-- Zapytanie jest odpowiednikiem kompleksowego zapytania z modu³u zakupów. Pokazuje ca³y proces sprzeda¿y: klient sk³ada zamówienie -> produkty s¹ kompletowane -> wystawiana jest faktura -> zamówienie zostaje dostarczone.
SELECT
    o.OrderID,
    c.CustomerName,
    si.StockItemName,
    o.OrderDate,
    o.ExpectedDeliveryDate,
    i.InvoiceDate,
    i.ConfirmedDeliveryTime,
    ol.Quantity,
    il.UnitPrice,
    il.ExtendedPrice,
    il.LineProfit
FROM Sales.Orders o
JOIN Sales.Customers c ON o.CustomerID = c.CustomerID
JOIN Sales.OrderLines ol ON o.OrderID = ol.OrderID
JOIN Warehouse.StockItems si ON ol.StockItemID = si.StockItemID
JOIN Sales.Invoices i ON o.OrderID = i.OrderID
JOIN Sales.InvoiceLines il ON i.InvoiceID = il.InvoiceID
   AND il.StockItemID = ol.StockItemID
ORDER BY o.OrderDate;

/* Podsumowanie modu³ów */

-- Wartoœæ zakupów i póŸniejszej sprzeda¿y produktów. Porównanie wartoœci zakupu produktów z przychodem ze sprzeda¿y.
-- Analiza ile firma wyda³a na zakup produktu i ile zarobi³a na jego sprzeda¿y.
SELECT
	si.StockItemName,
	SUM(pol.OrderedOuters * pol.ExpectedUnitPricePerOuter) AS WartoscZakupu,
	SUM(il.ExtendedPrice) AS WartoscSprzedazy
FROM Warehouse.StockItems si
LEFT JOIN Purchasing.PurchaseOrderLines pol ON si.StockItemID = pol.StockItemID
LEFT JOIN Sales.InvoiceLines il ON si.StockItemID = il.StockItemID
GROUP BY si.StockItemName
ORDER BY WartoscSprzedazy DESC;

SELECT
    si.StockItemName,
    AVG(pol.ExpectedUnitPricePerOuter) AS SredniaCenaZakupu,
    SUM(pol.OrderedOuters * pol.ExpectedUnitPricePerOuter) AS WartoscZakupu,
    AVG(il.UnitPrice) AS SredniaCenaSprzedazy,
    SUM(il.ExtendedPrice) AS WartoscSprzedazy
FROM Warehouse.StockItems si
LEFT JOIN Purchasing.PurchaseOrderLines pol ON si.StockItemID = pol.StockItemID
LEFT JOIN Sales.InvoiceLines il ON si.StockItemID = il.StockItemID
GROUP BY si.StockItemName
ORDER BY WartoscSprzedazy DESC;

-- Produkty przynosz¹ce najwiêkszy zysk. Od którego dostawcy pochodz¹ najbardziej dochodowe produkty.
SELECT
	s.SupplierName,
	si.StockItemName,
	SUM(il.LineProfit) AS Zysk
FROM Warehouse.StockItems si
JOIN Purchasing.Suppliers s ON si.SupplierID = s.SupplierID
JOIN Sales.InvoiceLines il ON si.StockItemID = il.StockItemID
GROUP BY s.SupplierName, si.StockItemName
ORDER BY Zysk DESC;

-- Ranking dostawców wed³ug wygenerowanego zysku
SELECT
    s.SupplierName,
    SUM(il.LineProfit) AS CalkowityZysk
FROM Purchasing.Suppliers s
JOIN Warehouse.StockItems si ON s.SupplierID=si.SupplierID
JOIN Sales.InvoiceLines il ON si.StockItemID=il.StockItemID
GROUP BY s.SupplierName
ORDER BY CalkowityZysk DESC;

-- Najlepsi klienci dla poszczególnych dostawców
SELECT
    s.SupplierName,
    c.CustomerName,
    SUM(il.ExtendedPrice) AS Sprzedaz
FROM Purchasing.Suppliers s
JOIN Warehouse.StockItems si ON s.SupplierID=si.SupplierID
JOIN Sales.InvoiceLines il ON si.StockItemID=il.StockItemID
JOIN Sales.Invoices i ON il.InvoiceID=i.InvoiceID
JOIN Sales.Customers c ON i.CustomerID=c.CustomerID
GROUP BY
s.SupplierName,
c.CustomerName
ORDER BY
s.SupplierName,
Sprzedaz DESC;

-- Produkty najczêœciej kupowane i sprzedawane
SELECT
	si.StockItemName,
	SUM(pol.OrderedOuters) AS Zakupiono,
	SUM(il.Quantity) AS Sprzedano
FROM Warehouse.StockItems si
LEFT JOIN Purchasing.PurchaseOrderLines pol ON si.StockItemID = pol.StockItemID
LEFT JOIN Sales.InvoiceLines il ON si.StockItemID = il.StockItemID
GROUP BY si.StockItemName;

-- Produkty, które nigdy siê nie sprzeda³y
SELECT
	si.StockItemName
FROM Warehouse.StockItems si
WHERE NOT EXISTS
(
	SELECT * FROM Sales.InvoiceLines il
	WHERE il.StockItemID = si.StockItemID
);

-- Œredni zysk produktu wed³ug dostawców
SELECT
	s.SupplierName,
	AVG(il.LineProfit) AS SredniZysk
FROM Purchasing.Suppliers s
JOIN Warehouse.StockItems si ON s.SupplierID = si.SupplierID
JOIN Sales.InvoiceLines il ON si.StockItemID = il.StockItemID
GROUP BY s.SupplierName
ORDER BY SredniZysk DESC;

-- Produkty z mar¿¹ wiêksz¹ od œredniej
WITH Marza AS
(
SELECT
    si.StockItemID,
    si.StockItemName,
    AVG(il.UnitPrice-pol.ExpectedUnitPricePerOuter) AS Marza
FROM Warehouse.StockItems si
JOIN Purchasing.PurchaseOrderLines pol ON si.StockItemID=pol.StockItemID
JOIN Sales.InvoiceLines il ON si.StockItemID=il.StockItemID
GROUP BY
	si.StockItemID,
	si.StockItemName
)

SELECT * FROM Marza
WHERE Marza >
(
	SELECT AVG(Marza)
	FROM Marza
);

-- Widok: po³¹czenie daty zamówienia zakupu dostawców z dat¹ dostarczenia produktów
CREATE VIEW view_DeliveryPerformance AS
SELECT 
	po.PurchaseOrderID,
	po.OrderDate,
	po.ExpectedDeliveryDate,
	MAX(pol.LastReceiptDate) AS DataPrzyjecia,
	DATEDIFF(
			DAY,
			po.ExpectedDeliveryDate,
			MAX(pol.LastReceiptDate)
			) AS Opoznienie
FROM Purchasing.PurchaseOrders po
JOIN Purchasing.PurchaseOrderLines pol ON po.PurchaseOrderID = pol.PurchaseOrderLineID
GROUP BY
	po.PurchaseOrderID,
	po.OrderDate,
	po.ExpectedDeliveryDate;

SELECT * FROM view_DeliveryPerformance;