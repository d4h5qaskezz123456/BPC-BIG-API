codeunit 80001 "BPC.InsertStmtNotoItemLedEnt"
{
    Permissions = TableData 32 = rimd;
    TableNo = 99001485;

    trigger OnRun()
    begin
        InsertStmtNo(rec);
    end;

    procedure InsertStmtNo(var PostedStmt: Record "LSC Posted Statement")
    var
        TransactionHeader: Record "LSC Transaction Header";
        ItemLedgerEntry: Record "Item Ledger Entry";
        DocumentNo: Text[20];
        PostedStatementNo: Code[20];
    begin
        TransactionHeader.Reset();
        TransactionHeader.SetRange("Posted Statement No.", PostedStmt."No.");
        if TransactionHeader.FindSet() then
            repeat
                Clear(DocumentNo);
                Clear(PostedStatementNo);
                TransactionHeader.CalcFields("Posted Statement No.");
                DocumentNo := StrSubstNo('%1-%2-%3', TransactionHeader."Store No.", TransactionHeader."POS Terminal No.", TransactionHeader."Transaction No.");
                PostedStatementNo := TransactionHeader."Posted Statement No.";
                ItemLedgerEntry.Reset();
                ItemLedgerEntry.SetRange("Document No.", DocumentNo);
                if ItemLedgerEntry.FindSet() then begin
                    ItemLedgerEntry."BPC.Statement No." := PostedStatementNo;
                    ItemLedgerEntry.Modify();
                end;
            until TransactionHeader.Next() = 0;

        Message('OK');
    end;

    // procedure QuantityReceived()
    // var
    //     PurchaseHeader: Record "Purchase Header";
    //     Purchaseline: Record "Purchase Line";
    // begin
    //     PurchaseHeader.Reset();
    //     PurchaseHeader.SetRange("No.", 'POI23000011');
    //     if PurchaseHeader.FindSet() then begin
    //         Purchaseline.Reset();
    //         Purchaseline.SetRange(Purchaseline."Document No.", PurchaseHeader."No.");
    //         Purchaseline.SetFilter("Document Type", '%1', Purchaseline."Document Type"::Order);
    //         if Purchaseline.FindSet() then begin
    //             repeat
    //                 Purchaseline."Quantity Received" := 0;
    //                 Purchaseline."Qty. Rcd. Not Invoiced" := 0;
    //                 Purchaseline.Modify();
    //             until Purchaseline.Next() = 0;
    //         end;
    //         Message('OK');
    //     end;


    // end;


}