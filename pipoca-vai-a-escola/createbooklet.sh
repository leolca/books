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

cp pdf_pages/pipoca_capa.pdf "${TEMP_DIR}/01.pdf"
pdfjam pdf_pages/pipoca_i.pdf pdf_pages/pipoca_ii.pdf --nup 2x1 --landscape --a4paper --outfile "${TEMP_DIR}/02.pdf" --quiet
pdfjam pdf_pages/pipoca_iii.pdf pdf_pages/pipoca_iv.pdf --nup 2x1 --landscape --a4paper --outfile "${TEMP_DIR}/03.pdf" --quiet
cp pdf_pages/pipoca01.pdf "${TEMP_DIR}/04.pdf"
cp pdf_pages/pipoca02.pdf "${TEMP_DIR}/05.pdf"
cp pdf_pages/pipoca03.pdf "${TEMP_DIR}/06.pdf"
cp pdf_pages/pipoca04.pdf "${TEMP_DIR}/07.pdf"
cp pdf_pages/pipoca05.pdf "${TEMP_DIR}/08.pdf"
cp pdf_pages/pipoca06.pdf "${TEMP_DIR}/09.pdf"
cp pdf_pages/pipoca07.pdf "${TEMP_DIR}/10.pdf"
cp pdf_pages/pipoca08.pdf "${TEMP_DIR}/11.pdf"
cp pdf_pages/pipoca09.pdf "${TEMP_DIR}/12.pdf"
cp pdf_pages/pipoca10.pdf "${TEMP_DIR}/13.pdf"
cp pdf_pages/pipoca11.pdf "${TEMP_DIR}/14.pdf"
cp pdf_pages/pipoca12.pdf "${TEMP_DIR}/15.pdf"
cp pdf_pages/pipoca13.pdf "${TEMP_DIR}/16.pdf"
pdftk ${TEMP_DIR}/*.pdf cat output book_pipoca.pdf 
gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS=/ebook -dNOPAUSE -dBATCH -sOutputFile=ebook_pipoca.pdf book_pipoca.pdf


rm ${TEMP_DIR}/*
mutool poster -x 2 pdf_pages/pipoca_capa.pdf "${TEMP_DIR}/temp.pdf"
pdfseparate "${TEMP_DIR}/temp.pdf" "${TEMP_DIR}/cover%d.pdf"
for i in {1..13}; 
  do 
  echo $i;
  formatted_i=$(printf "%02d" "$i")
  mutool poster -x 2 "pdf_pages/pipoca${formatted_i}.pdf" "${TEMP_DIR}/temp.pdf"
  pdfseparate "${TEMP_DIR}/temp.pdf" "${TEMP_DIR}/booklet${formatted_i}_%d.pdf"
done

pdftk ${TEMP_DIR}/cover2.pdf pdf_pages/pipoca_i.pdf pdf_pages/pipoca_ii.pdf pdf_pages/pipoca_iii.pdf pdf_pages/pipoca_iv.pdf ${TEMP_DIR}/booklet* ${TEMP_DIR}/cover1.pdf cat output booklet_pipoca.pdf
pdfjam --booklet true --landscape --a4paper booklet_pipoca.pdf --outfile booklet_pipoca_print.pdf --quiet

cp booklet_pipoca_print.pdf "${TEMP_DIR}/input.pdf"
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
cp "${TEMP_DIR}/bookcm.pdf" "booklet_pipoca_print_with_crop_marks.pdf"

echo "Booklet PDF with crop marks created."

echo "Script finished."
