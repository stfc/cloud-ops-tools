# A collection of unrelated utils and tools 

## txt2pdf.py [here](txt2pdf.py)

### Description
* Primary purpose: generate pdf docs for the period CLOUD reports. 
* Converts ascii text into a pdf document. 
* If the input file contains basic markdown tags, they are recognised and processed accordingly. 
    * Tables
    * Titles
    * bold face 
* Each title starts on a new page.
* A title page is created, with the current date. 
* Execute "txt2pdf.py -h" for help on the input options. 

### Installation and Setup
* **dependency**:reportlab

### TO-DO and Whishlist
* Improve quality of the code, make it more modular
* Improve the -h/--help message to explain better the different combinations of input options
* Add CLOUD-specific code, to enhance the content of the generated document. For example: some **warning** or **critical** alert when some numbers are not good.
