#region Update-DEP-Item Ledger
//Kim 2025-03 ++
codeunit 80009 "BPC.API.UpdateDepItemLedg"
{
    Permissions = tabledata "Item Ledger Entry" = rimd, tabledata "Value Entry" = rimd;
    trigger OnRun()
    begin
        Code();
    end;

    local procedure Code()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
        TransSalesEntry: Record "LSC Trans. Sales Entry";
        Item: Record Item;
        Store: Record "LSC Store";
        TmpTransSalesEntry: Record "LSC Trans. Sales Entry" temporary;
        DocNo: Text;
        ILEEntryNo: Integer;
        VEEntryNo: Integer;
        Window: Dialog;
        RequestPageFilter: FilterPageBuilder;
        FilterName: Text;
    begin
        FilterName := 'Trans. Sales Entry';
        TransSalesEntry.SetCurrentKey(Date, "Item No.");
        TransSalesEntry.SetFilter("Item No.", 'DS');
        TransSalesEntry.SetFilter(Date, '%1..%2', 20250312D, 20250325D);
        RequestPageFilter.ADDTABLE(FilterName, DATABASE::"LSC Trans. Sales Entry");
        RequestPageFilter.SetView(FilterName, TransSalesEntry.GetView());
        IF not RequestPageFilter.RUNMODAL THEN
            exit;
        TransSalesEntry.SETVIEW(RequestPageFilter.GETVIEW(FilterName));

        Window.Open('Processing ...');

        TmpTransSalesEntry.Reset();
        TmpTransSalesEntry.DeleteAll();

        if TransSalesEntry.FindSet() then
            repeat
                DocNo :=
                    StrSubstNo('%1-%2-%3',
                        TransSalesEntry."Store No.", TransSalesEntry."POS Terminal No.", TransSalesEntry."Transaction No.");

                ItemLedgerEntry.Reset();
                ItemLedgerEntry.SetRange("Document No.", DocNo);
                ItemLedgerEntry.SetRange("Item No.", TransSalesEntry."Item No.");
                if not ItemLedgerEntry.FindFirst() then begin
                    TmpTransSalesEntry.Reset();
                    TmpTransSalesEntry.SetRange("Store No.", TransSalesEntry."Store No.");
                    TmpTransSalesEntry.SetRange("POS Terminal No.", TransSalesEntry."POS Terminal No.");
                    TmpTransSalesEntry.SetRange("Transaction No.", TransSalesEntry."Transaction No.");
                    if not TmpTransSalesEntry.FindFirst() then begin
                        TmpTransSalesEntry := TransSalesEntry;
                        TmpTransSalesEntry.Insert();
                    end else begin
                        TmpTransSalesEntry.Quantity += TransSalesEntry.Quantity;
                        TmpTransSalesEntry."Cost Amount" += TransSalesEntry."Cost Amount";
                        TmpTransSalesEntry."Net Amount" += TransSalesEntry."Net Amount";
                        TmpTransSalesEntry."Discount Amount" += TransSalesEntry."Discount Amount";
                        TmpTransSalesEntry.Modify();
                    end;
                end;
            until TransSalesEntry.Next() = 0;

        ItemLedgerEntry.LockTable();
        ValueEntry.LockTable();

        ItemLedgerEntry.Reset();
        if ItemLedgerEntry.FindLast() then
            ILEEntryNo := ItemLedgerEntry."Entry No.";

        ValueEntry.Reset();
        if ValueEntry.FindLast() then
            VEEntryNo := ValueEntry."Entry No.";

        TmpTransSalesEntry.Reset();
        if TmpTransSalesEntry.FindSet() then
            repeat
                Item.Get(TmpTransSalesEntry."Item No.");
                Store.Get(TmpTransSalesEntry."Store No.");
                DocNo :=
                    StrSubstNo('%1-%2-%3',
                        TmpTransSalesEntry."Store No.", TmpTransSalesEntry."POS Terminal No.", TmpTransSalesEntry."Transaction No.");

                ItemLedgerEntry.Init();
                ItemLedgerEntry."Item No." := TmpTransSalesEntry."Item No.";
                ItemLedgerEntry."Posting Date" := TmpTransSalesEntry.Date;
                ItemLedgerEntry."Entry Type" := ItemLedgerEntry."Entry Type"::Sale;
                ItemLedgerEntry."Document No." := DocNo;
                ItemLedgerEntry.Description := Item.Description;
                ItemLedgerEntry."Location Code" := Store."Location Code";
                ItemLedgerEntry.Quantity := TmpTransSalesEntry.Quantity;
                ItemLedgerEntry."Remaining Quantity" := TmpTransSalesEntry.Quantity;
                ItemLedgerEntry."Invoiced Quantity" := TmpTransSalesEntry.Quantity;
                ItemLedgerEntry.Open := true;
                ItemLedgerEntry.Positive := false;
                ItemLedgerEntry."Document Date" := TmpTransSalesEntry.Date;
                ItemLedgerEntry."Qty. per Unit of Measure" := 1;
                ItemLedgerEntry."Unit of Measure Code" := 'ITEM';
                ItemLedgerEntry."Item Category Code" := TmpTransSalesEntry."Item Category Code";
                ItemLedgerEntry."Completely Invoiced" := true;
                ItemLedgerEntry."Last Invoice Date" := TmpTransSalesEntry.Date;
                ItemLedgerEntry."Shipped Qty. Not Returned" := TmpTransSalesEntry.Quantity;
                ItemLedgerEntry."Item Tracking" := ItemLedgerEntry."Item Tracking"::None;
                ItemLedgerEntry."BPC.User ID" := TmpTransSalesEntry."Store No.";
                ItemLedgerEntry."BPC.Statement No." := TmpTransSalesEntry."Store No.";
                ItemLedgerEntry."LSC Retail Product Code" := TmpTransSalesEntry."Retail Product Code";
                ItemLedgerEntry."LSC Statement No." := DocNo;

                ILEEntryNo += 1;
                ItemLedgerEntry."Entry No." := ILEEntryNo;
                ItemLedgerEntry.Insert();

                ValueEntry.Init();
                ValueEntry."Item No." := TmpTransSalesEntry."Item No.";
                ValueEntry."Posting Date" := TmpTransSalesEntry.Date;
                ValueEntry."Item Ledger Entry Type" := ValueEntry."Item Ledger Entry Type"::Sale;
                ValueEntry."Document No." := DocNo;
                ValueEntry.Description := Item.Description;
                ValueEntry."Location Code" := Store."Location Code";
                ValueEntry."Item Ledger Entry No." := ILEEntryNo;
                ValueEntry."Valued Quantity" := TmpTransSalesEntry.Quantity;
                ValueEntry."Item Ledger Entry Quantity" := TmpTransSalesEntry.Quantity;
                ValueEntry."Invoiced Quantity" := TmpTransSalesEntry.Quantity;
                if TmpTransSalesEntry.Quantity <> 0 then
                    ValueEntry."Cost per Unit" := TmpTransSalesEntry."Cost Amount" / TmpTransSalesEntry.Quantity;
                ValueEntry."Sales Amount (Actual)" := TmpTransSalesEntry."Net Amount";
                ValueEntry."Salespers./Purch. Code" := TmpTransSalesEntry."Sales Staff";
                ValueEntry."Discount Amount" := TmpTransSalesEntry."Discount Amount";
                ValueEntry."User ID" := TmpTransSalesEntry."Store No.";
                ValueEntry."Source Code" := 'BACKOFFICE';
                ValueEntry."Cost Amount (Actual)" := TmpTransSalesEntry."Cost Amount";
                ValueEntry."Gen. Bus. Posting Group" := TmpTransSalesEntry."Gen. Bus. Posting Group";
                ValueEntry."Gen. Prod. Posting Group" := TmpTransSalesEntry."Gen. Prod. Posting Group";
                ValueEntry."Document Date" := TmpTransSalesEntry.Date;
                ValueEntry."VAT Reporting Date" := TmpTransSalesEntry.Date;
                ValueEntry.Inventoriable := true;
                ValueEntry."Valuation Date" := TmpTransSalesEntry.Date;
                ValueEntry."Entry Type" := ValueEntry."Entry Type"::"Direct Cost";
                ValueEntry."LSC Retail Product Code" := TmpTransSalesEntry."Retail Product Code";
                ValueEntry."LSC Item Category" := TmpTransSalesEntry."Item Category Code";
                ValueEntry."LSC Item No." := TmpTransSalesEntry."Item No.";
                ValueEntry."LSC Posting Date" := TmpTransSalesEntry.Date;
                ValueEntry."LSC Item Ledger Entry Type" := ValueEntry."LSC Item Ledger Entry Type"::Sale;
                ValueEntry."LSC Location Code" := Store."Location Code";
                ValueEntry."LSC Valued Quantity" := TmpTransSalesEntry.Quantity;
                ValueEntry."LSC Invoiced Quantity" := TmpTransSalesEntry.Quantity;
                ValueEntry."LSC Sales Amount (Actual)" := TmpTransSalesEntry."Net Amount";
                ValueEntry."LSC Salespers./Purch. Code" := TmpTransSalesEntry."Sales Staff";
                ValueEntry."LSC Discount Amount" := TmpTransSalesEntry."Discount Amount";
                ValueEntry."LSC Cost Amount (Actual)" := TmpTransSalesEntry."Cost Amount";

                VEEntryNo += 1;
                ValueEntry."Entry No." := VEEntryNo;
                ValueEntry.Insert();
            until TmpTransSalesEntry.Next() = 0;

        Window.Close();
        Message('Completed.');
    end;
}
//Kim 2025-03 --
#endregion