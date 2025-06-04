pageextension 80021 "BPC.LSC Posted Statement" extends "LSC Posted Statement"
{
    layout
    {
        addlast(General)
        {
            field("BPC Send To FO"; Rec."BPC Send To FO")
            {
                Caption = 'Send To FO';
                ApplicationArea = all;
                ToolTip = 'Send To FO';
                Editable = false;
            }
        }
    }
    actions
    {
        addafter("Statement - Product Group Sales")
        {
            action(ReSend_Interface_to_D365)
            {
                ApplicationArea = all;
                Caption = 'Re-Send Interface to D365';
                Image = Action;
                trigger OnAction()
                var
                    RetailSetup: Record "LSC Retail Setup";
                    PostedStmt: Record "LSC Posted Statement";
                    InterfaceData: Codeunit "BPC.Interface Data";
                begin
                    RetailSetup.Get();
                    RetailSetup.TestField("bpc.Interface D365 Active");
                    if Confirm('Re-Send Interface to D365 ?', true, Rec."No.") then
                        IF RetailSetup."BPC.Interface D365 Active" THEN BEGIN
                            //เสือ by พี่เซี้ยะ
                            // if not InterfaceDataCU.ValidPostedStatementSalesQty(Rec, false) then
                            //     Error('Can''t send interface');
                            //เสือ by พี่เซี้ยะ
                            PostedStmt.RESET();
                            PostedStmt.SETRANGE("No.", rec."No.");
                            IF PostedStmt.FINDSET() THEN BEGIN
                                InterfaceData.PostStmtJnlToFO(PostedStmt, true);//CustPayment
                                InterfaceData.PostStmtMovementToFO(PostedStmt, true);//SalesOrder

                                PostedStmt."BPC Send To FO" := true;
                                PostedStmt.Modify();
                            END;
                        END;
                end;
            }
            action("ViewMovementQty&JournalQty")
            {
                ApplicationArea = all;
                Caption = 'View Movement Qty & Journal Qty';
                Image = Action;
                trigger OnAction()
                begin
                    if not InterfaceDataCU.ValidPostedStatementSalesQty(Rec, true) then
                        Error('Can''t send interface')
                    else
                        Error('Can send interface');
                end;
            }
        }
        addafter("Statement - Product Group Sales_Promoted")
        {
            actionref("ReSend_Interface_to_D365_Promoted"; ReSend_Interface_to_D365) { }
            actionref("ViewMovementQty&JournalQty_Promoted"; "ViewMovementQty&JournalQty") { }
        }
    }

    var
        InterfaceDataCU: Codeunit "BPC.Interface Data";

    // local procedure ValidSalesQty(): Boolean
    // var
    //     TransactionHdr: Record "LSC Transaction Header";
    //     ItemLedgerEnt: Record "Item Ledger Entry";
    //     TransSalesEnt: Record "LSC Trans. Sales Entry";
    //     MovementQty: Decimal;
    //     JournalQty: Decimal;
    // begin
    //     MovementQty := 0;
    //     JournalQty := 0;

    //     TransactionHdr.SetRange("Posted Statement No.", Rec."No.");
    //     TransactionHdr.SetRange("Transaction Type", TransactionHdr."Transaction Type"::Sales);
    //     if TransactionHdr.FindSet() then
    //         repeat
    //             ItemLedgerEnt.Reset();
    //             ItemLedgerEnt.SetRange("Document No.", StrSubstNo('%1-%2-%3', TransactionHdr."Store No.", TransactionHdr."POS Terminal No.", TransactionHdr."Transaction No."));
    //             ItemLedgerEnt.SetRange("Entry Type", "Item Ledger Entry Type"::Sale);
    //             if ItemLedgerEnt.FindSet() then begin
    //                 ItemLedgerEnt.CalcSums(Quantity);
    //                 MovementQty += ItemLedgerEnt.Quantity;
    //             end;

    //             TransSalesEnt.Reset();
    //             TransSalesEnt.SetRange("Store No.", TransactionHdr."Store No.");
    //             TransSalesEnt.SetRange("POS Terminal No.", TransactionHdr."POS Terminal No.");
    //             TransSalesEnt.SetRange("Transaction No.", TransactionHdr."Transaction No.");
    //             if TransSalesEnt.FindSet() then begin
    //                 TransSalesEnt.CalcSums(Quantity);
    //                 JournalQty += TransSalesEnt.Quantity;
    //             end;

    //         until TransactionHdr.Next() = 0;

    //     Message('Statement No.: %1\Movement Qty: %2\Journal Qty:%3', Rec."No.", Abs(MovementQty), Abs(JournalQty));

    //     exit(MovementQty = JournalQty);
    // end;
}