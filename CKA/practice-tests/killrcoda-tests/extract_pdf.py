import sys

def extract_text(pdf_path, output_path):
    text_content = ""
    start_extraction = False
    
    # Try pymupdf (fitz) first
    try:
        import fitz
        print("Using fitz (pymupdf)...")
        doc = fitz.open(pdf_path)
        for page in doc:
            text_content += page.get_text() + "\n---PAGE BREAK---\n"
        start_extraction = True
    except ImportError:
        print("fitz not found, trying pypdf...")
        # Try pypdf
        try:
            from pypdf import PdfReader
            reader = PdfReader(pdf_path)
            for page in reader.pages:
                text_content += page.extract_text() + "\n---PAGE BREAK---\n"
            start_extraction = True
        except ImportError:
            print("ERROR: Neither fitz nor pypdf is available.")
            sys.exit(1)
            
    if start_extraction:
        try:
            with open(output_path, 'w', encoding='utf-8') as f:
                f.write(text_content)
            print(f"Successfully extracted text to {output_path}")
        except Exception as e:
            print(f"Error writing to file: {e}")
            sys.exit(1)

if __name__ == "__main__":
    pdf_path = '/Users/sanjeevmurthy/le/repos/le-kubernetes/CKA/Killrcoda/Simulator 1.pdf'
    output_path = '/Users/sanjeevmurthy/le/repos/le-kubernetes/CKA/Killrcoda/simulator_content.txt'
    extract_text(pdf_path, output_path)
