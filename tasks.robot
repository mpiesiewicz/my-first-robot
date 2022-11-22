*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.HTTP
Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.Robocloud.Items
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.Images
Library             RPA.Archive
Library             RPA.FileSystem


*** Variables ***
${RECEIPTS_FOLDER}          ${OUTPUT_DIR}${/}Receipts${/}
${SCREENSHOTS_FOLDER}       ${OUTPUT_DIR}${/}Screenshots${/}


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    ${Orders}=    Get orders
    Open orders page
    FOR    ${Order}    IN    @{Orders}
        Wait Until Keyword Succeeds    5x    0.5 sec    Process one order    ${Order}
    END
    Create a ZIP file of the receipts


*** Keywords ***
Get orders
    Log    Downloading Input File...
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True
    ${Table}=    Read table from CSV    orders.csv
    Log    File read successfully!
    RETURN    ${Table}

Open orders page
    Log    Opening Browser...
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order
    Log    Browser opened.

Close cookies popup
    Log    Closing annoying popup...
    Click Button When Visible    css:div.alert-buttons > button.btn.btn-dark
    Log    Popup closed.

Process one order
    [Arguments]    ${Order}
    Log    Processing order no.: ${Order}[Order number]
    Reload Page
    Close cookies popup

    Log    Filling the fields...
    Select From List By Value    head    ${Order}[Head]
    Select Radio Button    body    ${Order}[Body]
    Input Text    css:input[class=form-control][type=number]    ${Order}[Legs]
    Input Text    address    ${Order}[Address]
    Click Button    preview
    Click Button    order
    Log    Order sent.

    Save output    ${Order}
    Click Button    order-another
    # TODO div[role=alert]

Save output
    [Arguments]    ${Order}

    ${screenshot_path}=    Catenate
    ...    SEPARATOR=
    ...    ${SCREENSHOTS_FOLDER}
    ...    ${Order}[Order number]
    ...    -robot.png

    # ${screenshot_path}=    ${SCREENSHOTS_FOLDER}${Order}[Order number] why this wont work?

    ${pdf_path}=    Catenate
    ...    SEPARATOR=
    ...    ${RECEIPTS_FOLDER}
    ...    ${Order}[Order number]
    ...    -receipt.pdf

    ${files}=    Create List    ${screenshot_path}

    Log    Copying Receipt to PDF...
    ${receipt_html}=    Get Element Attribute    receipt    outerHTML
    Html To Pdf    ${receipt_html}    ${pdf_path}

    Log    Saving the screenshot...
    Screenshot    robot-preview-image    ${screenshot_path}

    Log    Appending Screenshot to PDF...
    Add Files To Pdf    ${files}    ${pdf_path}    True

Create a ZIP file of the receipts
    Log    Zipping the files...
    Archive Folder With Zip    ${RECEIPTS_FOLDER}    ${OUTPUT_DIR}${/}Receipts.zip
    Log    Files zipped.
