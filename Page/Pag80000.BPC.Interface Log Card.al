page 80000 "BPC.Interface Log Card"
{
    Caption = 'Interface Log Card';
    ApplicationArea = all;
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = Document;
    RefreshOnActivate = true;
    SourceTable = "BPC.Interface Log API";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                Editable = false;
                field("BPC.Interface Type"; Rec."BPC.Interface Type")
                {
                }
                field("BPC.Document No."; Rec."BPC.Document No.")
                {
                }
                field("BPC.Entry No."; Rec."BPC.Entry No.")
                {
                }
                field("BPC.Interface Date"; Rec."BPC.Interface Date")
                {
                }
                field("BPC.Interface Time"; Rec."BPC.Interface Time")
                {
                }
                field("BPC.Interface DateTime"; Rec."BPC.Interface DateTime")
                {
                }
                field("BPC.User ID"; Rec."BPC.User ID")
                {
                }
                group("URL Interface D365")
                {
                    field("BPC.Interface URL"; Rec."BPC.Interface URL")
                    {
                        MultiLine = true;
                        ShowCaption = false;
                    }
                }
            }
            group("Interface Log")
            {
                Caption = 'Interface Log';
                Editable = false;
                group("Request D365")
                {
                    field(RequestD365Log; RequestD365Log)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Request D365 Log';
                        Editable = false;
                        Importance = Additional;
                        MultiLine = true;
                        ShowCaption = false;
                        ToolTip = 'Specifies the products or service being offered';
                    }
                }
                group("D365 Response")
                {
                    field(D365ResponseLog; D365ResponseLog)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'D365 Response Log';
                        Editable = false;
                        Importance = Additional;
                        MultiLine = true;
                        ShowCaption = false;
                        ToolTip = 'Specifies the products or service being offered';
                    }
                }
            }
            group("Convert Base64 To String")
            {
                Caption = 'Convert Base64 To String';
                group(Base64)
                {
                    field(Base64Text; Base64Text)
                    {
                        MultiLine = true;
                        ShowCaption = false;

                        trigger OnValidate()
                        begin
                            IF Base64Text <> '' THEN
                                StringText := (Convert.FromBase64(Base64Text));
                        end;
                    }
                }
                group(String)
                {
                    Editable = false;
                    field(StringText; StringText)
                    {
                        MultiLine = true;
                        ShowCaption = false;
                    }
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        CLEAR(Base64Text);
        CLEAR(StringText);
        GetD365ResponseLog();
        GetRequestD365Log();
    end;

    trigger OnOpenPage()
    var
        PaymentServiceSetup: Record "Payment Service Setup";
        OfficeMgt: Codeunit "Office Management";
        PermissionManager: Codeunit "Permission Manager";
    begin
    end;

    var
        JSONMgt: Codeunit "JSON Management";
        JArrayData: JsonArray;
        JObjectData: JsonObject;
        Convert: Codeunit "Base64 Convert";
        // Encoding: Codeunit json;
        RequestD365Log: Text;
        D365ResponseLog: Text;
        Base64Text: Text;
        StringText: Text;

    local procedure GetRequestD365Log()
    begin
        RequestD365Log := rec.GetRequestD365(TEXTENCODING::UTF8);
        //Error(RequestD365Log);
        IF RequestD365Log <> '' THEN BEGIN
            IF COPYSTR(RequestD365Log, 1, 1) = '[' THEN BEGIN
                JArrayData.ReadFrom(RequestD365Log);
                JArrayData.WriteTo(RequestD365Log);
                //JArrayData := JArrayData.Parse(RequestD365Log);
                // RequestD365Log := JArrayData.ToString;
            END ELSE
                IF COPYSTR(RequestD365Log, 1, 1) = '{' THEN BEGIN
                    JObjectData.ReadFrom(RequestD365Log);
                    JObjectData.WriteTo(RequestD365Log);
                END;
        END;
    end;

    local procedure GetD365ResponseLog()
    begin
        D365ResponseLog := rec.GetD365Response(TEXTENCODING::UTF8);
        IF D365ResponseLog <> '' THEN BEGIN
            IF COPYSTR(D365ResponseLog, 1, 1) = '[' THEN BEGIN
                JArrayData.ReadFrom(D365ResponseLog);
                JArrayData.WriteTo(D365ResponseLog);
                // JArrayData := JArrayData.Parse(D365ResponseLog);
                // D365ResponseLog := JArrayData.ToString;
            END ELSE
                IF COPYSTR(D365ResponseLog, 1, 1) = '{' THEN BEGIN
                    JObjectData.ReadFrom(D365ResponseLog);
                    JObjectData.WriteTo(D365ResponseLog);
                    // JObjectData := JObjectData.Parse(D365ResponseLog);
                    // D365ResponseLog := JObjectData.ToString;
                END;
        END;
    end;

    // trigger JArrayData::ListChanged(sender: Variant; e: DotNet ListChangedEventArgs)
    // begin
    // end;

    // trigger JArrayData::AddingNew(sender: Variant; e: DotNet AddingNewEventArgs)
    // begin
    // end;

    // trigger JArrayData::CollectionChanged(sender: Variant; e: DotNet NotifyCollectionChangedEventArgs)
    // begin
    // end;

    // trigger JObjectData::PropertyChanged(sender: Variant; e: DotNet PropertyChangedEventArgs)
    // begin
    // end;

    // trigger JObjectData::PropertyChanging(sender: Variant; e: DotNet PropertyChangingEventArgs)
    // begin
    // end;

    // trigger JObjectData::ListChanged(sender: Variant; e: DotNet ListChangedEventArgs)
    // begin
    // end;

    // trigger JObjectData::AddingNew(sender: Variant; e: DotNet AddingNewEventArgs)
    // begin
    // end;

    // trigger JObjectData::CollectionChanged(sender: Variant; e: DotNet NotifyCollectionChangedEventArgs)
    // begin
    // end;
}

