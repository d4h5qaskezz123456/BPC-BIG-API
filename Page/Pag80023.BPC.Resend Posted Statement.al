page 80015 "BPC.Resend Posted Statement"
{
    PageType = Document;
    ApplicationArea = All;
    Caption = 'Re Send Posted Statement';
    UsageCategory = Administration;
    layout
    {
        area(Content)
        {
            field(FromDate; FromDate)
            {
                ApplicationArea = All;
                Caption = 'Form Date';
            }
            field(ToDate; ToDate)
            {
                ApplicationArea = All;
                Caption = 'To Date';
            }
            field(Document; Document)
            {
                ApplicationArea = All;
                Caption = 'Document No.';
                TableRelation = "LSC Posted Statement";
            }
            field(Store; Store)
            {
                ApplicationArea = All;
                Caption = 'Store No.';
                TableRelation = "LSC Store";
            }
        }

    }

    actions
    {
        area(Processing)
        {
            action("Send")
            {
                ApplicationArea = All;
                Image = SendTo;
                Caption = 'Send';
                Promoted = true;
                PromotedCategory = Process;
                trigger OnAction()
                var
                    RetailSetup: Record "LSC Retail Setup";
                    PostedStmt: Record "LSC Posted Statement";
                    InterfaceData: Codeunit "BPC.Interface Data";
                    SelectedRecords: Record "LSC Posted Statement" temporary;
                    Msg: Text;
                    i: Integer;
                    n: Integer;
                    Window: Dialog;
                begin

                    RetailSetup.Get();
                    RetailSetup.TestField("bpc.Interface D365 Active");
                    if Confirm('Re-Send Interface to D365 ?') then
                        IF RetailSetup."BPC.Interface D365 Active" THEN BEGIN
                            //เสือ by พี่เซี้ยะ
                            // if not InterfaceDataCU.ValidPostedStatementSalesQty(Rec, false) then
                            //     Error('Can''t send interface');
                            //เสือ by พี่เซี้ยะ
                            ValidateDates();
                            Window.Open('Processing Send Interface to FO D365...\\Progress #1############');
                            PostedStmt.RESET();
                            PostedStmt.SetFilter("No.", Document);
                            PostedStmt.SetFilter("Store No.", Store);
                            PostedStmt.SETRANGE("Posted Date", FromDate, ToDate);
                            IF PostedStmt.FINDSET() THEN begin
                                repeat
                                    i += 1;
                                    n := PostedStmt.Count();
                                    Window.Update(1, StrSubstNo('%1 of %2', i, n));
                                    InterfaceData.PostStmtJnlToFO(PostedStmt, true);//CustPayment
                                    InterfaceData.PostStmtMovementToFO(PostedStmt, true);//SalesOrder

                                    PostedStmt."BPC Send To FO" := true;
                                    PostedStmt.Modify();
                                    Msg += PostedStmt."No." + ',';

                                until PostedStmt.Next() = 0;
                            end
                            else begin
                                Error('Document not found');
                            end;
                            Window.Close();
                            Message(Msg);
                        END;
                end;
            }
        }
    }

    local procedure ValidateDates()
    begin
        if (FromDate = 0D) or (ToDate = 0D) then
            Error('Please specify both From Date and To Date');

        if ToDate < FromDate then
            Error('To Date cannot be before From Date');
    end;

    var
        FromDate: Date;
        ToDate: Date;
        Document: Code[20];
        Store: Code[20];


}