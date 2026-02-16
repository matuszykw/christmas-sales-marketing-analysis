import pandas as pd


file_name = '../data/Christmas_Retail_Sales_and_Marketing.xlsx'
sheets_to_ignore = []
output_folder = '../data'

xl = pd.ExcelFile(file_name)
sheet_names = xl.sheet_names

for sheet in sheet_names:
    if sheet in sheets_to_ignore:
        print(f'Skipping sheet {sheet}')
        continue

    df = pd.read_excel(xl, sheet)
    clean_name = output_folder + '/' + sheet.lower().replace(' ', '_') + '.csv'
    df.to_csv(clean_name, index=False, encoding='utf-8')
    print(f'Saved sheet {clean_name}')

    del df

print('Done')