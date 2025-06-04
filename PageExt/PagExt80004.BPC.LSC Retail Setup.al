pageextension 80004 "BPC.LSC Retail Setup" extends "LSC Retail Setup"
{
    layout
    {
        addlast(content)
        {
            group("D365 Connection")
            {
                Caption = 'D365 Connection';
                field("D365 Connection Active"; REC."BPC.Interface D365 Active")
                {
                    ApplicationArea = all;
                }
                field("Require Member on Sales Trans."; rec."BPC.Require Member on Sales Trans.")
                {
                    ApplicationArea = all;
                }
                field("LS Post Receive before Sent"; REC."BPC.LS Post Receive before Sent")
                {
                    ApplicationArea = all;
                }
                group("Interface D365")
                {
                    field("Interface D365 Active"; REC."BPC.Interface D365 Active")
                    {
                        ApplicationArea = all;
                    }
                    // field("Interface User Name"; REC."BPC.Interface User Name")
                    // {
                    //     Editable = Not (REC."BPC.Interface D365 Active");
                    //     ApplicationArea = all;
                    // }
                    // field("Interface Password"; REC."BPC.Interface Password")
                    // {
                    //     Enabled = Not (REC."BPC.Interface D365 Active");
                    //     ApplicationArea = all;
                    // }
                    field("Interface Tenant ID"; REC."BPC.Interface Tenant ID")
                    {
                        Editable = Not (REC."BPC.Interface D365 Active");
                        ApplicationArea = all;
                    }
                    field("Interface ClientID"; REC."BPC.Interface ClientID")
                    {
                        Enabled = Not (REC."BPC.Interface D365 Active");
                        ApplicationArea = all;
                    }
                    field("Interface Client Secret"; REC."BPC.Interface Client Secret")
                    {
                        Enabled = Not (REC."BPC.Interface D365 Active");
                        ApplicationArea = all;
                    }
                    field("Interface Resource"; REC."BPC.Interface Resource")
                    {
                        Enabled = Not (REC."BPC.Interface D365 Active");
                        ApplicationArea = all;
                    }
                    field("Interface Company"; REC."BPC.Interface Company")
                    {
                        Enabled = Not (REC."BPC.Interface D365 Active");
                        ApplicationArea = all;
                    }
                }
            }
        }
    }

    actions
    {

        addafter("<Token Storage Setup>")
        {
            action(TestConnectInterface)
            {
                Caption = 'Test Connect Interface';
                ApplicationArea = all;
                Promoted = true;
                PromotedCategory = Process;
                Image = Continue;
                trigger OnAction()
                var
                    InterfaceData: Codeunit "BPC.Interface Data";
                begin
                    if (InterfaceData.APITestConnection <> '') then
                        Message('Interface Connect Successful.')
                    else
                        Error('Interface Not Connect.');
                    // InterfaceData.TestCallAPI
                end;
            }
            action(Getitem)
            {
                Caption = 'Getitem';
                ApplicationArea = all;
                Promoted = true;
                PromotedCategory = Process;
                Image = Continue;
                trigger OnAction()
                var
                    Getitem: Codeunit "BPC.Getitem";
                    toTime: Time;
                    TypeHelper: Codeunit "Type Helper";
                    dd: DateTime;
                    s: DateTime;
                    ssa: DateTime;
                    MyDuration: Duration;
                begin

                    Getitem.GetItem(false);
                    // Codeunit.Run(Codeunit::"BPC.Getitem")
                end;
            }
        }

        #region Update-DEP-Item Ledger
        //Kim 2025-03 ++
        addlast("F&unctions")
        {
            action("BPC.API.Update-DEP-Item Ledger")
            {
                ApplicationArea = All;
                Caption = 'Update-DEP-Item Ledger';
                trigger OnAction()
                begin
                    Codeunit.Run(Codeunit::"BPC.API.UpdateDepItemLedg");
                end;
            }
        }
        //Kim 2025-03 --
        #endregion

        #region Import Item Ledger
        //Kim 2025-03 ++
        addlast("F&unctions")
        {
            action("BPC.API.Import Item Ledger")
            {
                ApplicationArea = All;
                Caption = 'Import Item Ledger';
                Image = Import;
                RunObject = xmlport "BPC.API.ImportItemLedger";
                ToolTip = 'Insert data to item ledger entry and value entry';
            }
        }
        //Kim 2025-03 --
        #endregion
    }
}