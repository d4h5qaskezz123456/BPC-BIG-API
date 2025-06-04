codeunit 80003 "BPC.ClearMediaSet"
{
    Permissions = TableData 110 = rimd;
    TableNo = "Sales Shipment Header";
    trigger OnRun()
    var
        myInt: Integer;
    begin
        if rec."BPC.File PDF".Remove(rec."BPC.File PDF".Item(1)) then
            rec.Modify();
    end;

    procedure Remove(SalesShipmentHeader: Record "Sales Shipment Header")
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        BOUtils: Codeunit "LSC BO Utils";
        Guid: Guid;
    begin
        Guid := SalesShipmentHeader."BPC.File PDF".Item(1);
        if SalesShipmentHeader."BPC.File PDF".Remove(Guid) then begin
            SalesShipmentHeader.Modify();
            Message('OK%1 %2', Guid, SalesShipmentHeader."BPC.File PDF".Item(1));
        end else
            Message('NO');
    end;

}