#!/bin/bash

TEMP_DIR=$(mktemp -d)

cleanup() {
  echo "Cleaning up temporary directory: $TEMP_DIR"
  rm -rf "$TEMP_DIR"
}

# Call cleanup function on normal exit (0) and on signals that might terminate the script
trap cleanup EXIT SIGHUP SIGINT SIGTERM

# Your script logic here
echo "Working in temporary directory: $TEMP_DIR"

cp pdf_pages/livropipocadragon000-cover_en.pdf "${TEMP_DIR}/01.pdf"
cp pdf_pages/livropipocadragon-i_en.pdf "${TEMP_DIR}/02.pdf"
cp pdf_pages/livropipocadragon-ii_en.pdf "${TEMP_DIR}/03.pdf"
cp pdf_pages/livropipocadragon-iii_en.pdf "${TEMP_DIR}/04.pdf"
cp pdf_pages/livropipocadragon001_en.pdf "${TEMP_DIR}/05.pdf"
cp pdf_pages/livropipocadragon002_en.pdf "${TEMP_DIR}/06.pdf"
cp pdf_pages/livropipocadragon003_en.pdf "${TEMP_DIR}/07.pdf"
cp pdf_pages/livropipocadragon004_en.pdf "${TEMP_DIR}/08.pdf"
cp pdf_pages/livropipocadragon005_en.pdf "${TEMP_DIR}/09.pdf"
cp pdf_pages/livropipocadragon006_en.pdf "${TEMP_DIR}/10.pdf"
cp pdf_pages/livropipocadragon007_en.pdf "${TEMP_DIR}/11.pdf"
cp pdf_pages/livropipocadragon008_en.pdf "${TEMP_DIR}/12.pdf"
cp pdf_pages/livropipocadragon009_en.pdf "${TEMP_DIR}/13.pdf"
cp pdf_pages/livropipocadragon010_en.pdf "${TEMP_DIR}/14.pdf"
cp pdf_pages/livropipocadragon011_en.pdf "${TEMP_DIR}/15.pdf"
cp pdf_pages/livropipocadragon012_en.pdf "${TEMP_DIR}/16.pdf"
cp pdf_pages/livropipocadragon013_en.pdf "${TEMP_DIR}/17.pdf"
cp pdf_pages/livropipocadragon014_en.pdf "${TEMP_DIR}/18.pdf"
cp pdf_pages/livropipocadragon015_en.pdf "${TEMP_DIR}/19.pdf"
cp pdf_pages/livropipocadragon016_en.pdf "${TEMP_DIR}/20.pdf"
cp pdf_pages/livropipocadragon017_en.pdf "${TEMP_DIR}/21.pdf"
cp pdf_pages/livropipocadragon018_en.pdf "${TEMP_DIR}/22.pdf"
pdftk ${TEMP_DIR}/*.pdf cat output book_pipoca_en.pdf 
gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS=/ebook -dNOPAUSE -dBATCH -sOutputFile=ebook_pipoca_en.pdf book_pipoca_en.pdf


#rm ${TEMP_DIR}/*
#mutool poster -x 2 pdf_pages/livropipocadragon000-cover_en.pdf "${TEMP_DIR}/temp.pdf"
#pdfseparate "${TEMP_DIR}/temp.pdf" "${TEMP_DIR}/cover%d.pdf"
for i in {1..22}; 
  do 
  echo $i;
  formatted_i=$(printf "%02d" "$i")
  mutool poster -x 2 "${TEMP_DIR}/${formatted_i}.pdf" "${TEMP_DIR}/temp.pdf"
  pdfseparate "${TEMP_DIR}/temp.pdf" "${TEMP_DIR}/booklet${formatted_i}_%d.pdf"
done

pdftk ${TEMP_DIR}/booklet* cat output "${TEMP_DIR}/booklet_pipoca.pdf"
pdftk "${TEMP_DIR}/booklet_pipoca.pdf" cat 2-end 1 output booklet_pipoca_en.pdf
pdfjam --booklet true --landscape --a4paper booklet_pipoca_en.pdf --outfile booklet_pipoca_print_en.pdf --quiet

cp booklet_pipoca_print_en.pdf "${TEMP_DIR}/input.pdf"
c_folder=$(pwd)
cd $TEMP_DIR

pdftk input.pdf burst output page_%04d.pdf
for f in page_*.pdf; do
  n=$(echo "$f" | grep -o '[0-9]\+')
  if [ $((10#$n % 2)) -eq 0 ]; then
    pdftk "$f" cat 1south output "rot_$f"
  else
    cp "$f" "rot_$f"
  fi
done
pdftk $(ls rot_page_*.pdf | sort) cat output rotated.pdf

tex_file="bookcm.tex"
pdf_file="bookcm.pdf"

# Create the LaTeX file
cat > "$tex_file" <<EOF
\documentclass[a5paper,landscape]{article}
\usepackage[utf8]{inputenc}
\usepackage{pdfpages}
%\usepackage[
%  % set width and height to a4 width and height + 6mm
%  width=21.6truecm, height=30.3truecm,
%  % use any combination of these options to add different cut markings
%  cam, axes, frame, cross,
%  % set the type of TeX renderer you use
%  pdftex,
%  % center the contents
%  center
%]{crop}
%\usepackage[printwatermark]{xwatermark}
%\newwatermark*[allpages,color=red!50,angle=45,scale=3,xpos=0,ypos=0]{RASCUNHO}
%\newwatermark*[pages=1-100,color=gray!30,angle=45,scale=3,xpos=0,ypos=0]{RASCUNHO}
\usepackage[cam,a4,center]{crop}
\begin{document}
\includepdf[pages=-,landscape,angle=90]{rotated.pdf}
\end{document}
EOF

cd $TEMP_DIR
# Compile the LaTeX file
pdflatex bookcm.tex > /dev/null 2>&1
cd $c_folder

# Rename the output PDF
cp "${TEMP_DIR}/bookcm.pdf" "booklet_pipoca_print_with_crop_marks_en.pdf"

echo "Booklet PDF with crop marks created."

echo "Script finished."
