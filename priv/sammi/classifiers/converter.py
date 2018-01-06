
# THE PURPOSE OF THIS FILE IS TO CONVERT THE GIVEN FILE (USUALLY PDF OR DOCX)
# TO A VALID IMAGE FORMAT THAT CAN BE PARSED
import os
import sys

from wand.image import Image

class Converter:
    # Convert Module
    def convert(self,filepath):
        req_image = []

        image_pdf = Image(filename=filepath, resolution=300)
        # Image Blobs of Each PDF Page
        image_png = image_pdf.convert('png')

        # Append Each Blob to Array
        for img in image_png.sequence:
            img_page = Image(image=img)
            req_image.append(img_page.make_blob('png'))

        return req_image

# Allows Converter to Be Called as Script
if __name__ == "__main__":
    c = Converter()
    converted = c.convert(sys.argv[1])
    print(converted)
