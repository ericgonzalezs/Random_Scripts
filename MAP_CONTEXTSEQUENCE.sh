

#############mapping
bwa index HanXRQv2.fasta

sed '/--/d' context-sequences-AXIOM-markers.fa |  sed 's/\[A\/.\]/N/g' | sed 's/\[T\/.\]/N/g' | sed 's/\[C\/.\]/N/g' | sed 's/\[G\/.\]/N/g'  > context-sequences-AXIOM-markers_clean.fa

bwa mem HanXRQv2.fasta context-sequences-AXIOM-markers_clean.fa > context-sequences-AXIOM-markers_clean_vs_HanXRQv2.sam

########create table for Mareymap

#compress and sort
samtools view -b context-sequences-AXIOM-markers_clean_vs_HanXRQv2.sam > context-sequences-AXIOM-markers_clean_vs_HanXRQv2.bam
samtools sort context-sequences-AXIOM-markers_clean_vs_HanXRQv2.bam -o context-sequences-AXIOM-markers_clean_vs_HanXRQv2_sorted.bam

# obtain leght of the context sequence
grep -v ">" context-sequences-AXIOM-markers.fa | sed '/--/d' |  sed 's/\[A\/.\]/N/g' | sed 's/\[T\/.\]/N/g' | sed 's/\[C\/.\]/N/g' | sed 's/\[G\/.\]/N/g' | awk '{print length($0)}' > legths.
txt

#context sequence and name on the same row
sed '/--/d' context-sequences-AXIOM-markers.fa | awk '/^>/{printf "%s ",$0;next}{print}' > name_sequence.txt

#paste length and sequence name
paste  -d ' '  name_sequence.txt legths.txt  | sed 's/>//g' >  name_sequence_lenght.txt

#obtain the percentage of ID,  not used here
#samtools calmd context-sequences-AXIOM-markers_clean_vs_HanXRQv2_sorted.bam HanXRQv2.fasta | samtools view -bq 50 - | htsbox  samview -p - | awk '{print ($10/$11)*100}' > percentage_id.txt

#convert the alignment to paf file and select markers whose alignments have a MQ > 50, and the same length as the context sequence. Also, keep only alignments that have one snp or less between the context sequence and the reference genome
 samtools calmd context-sequences-AXIOM-markers_clean_vs_HanXRQv2_sorted.bam HanXRQv2.fasta | samtools view -bq 50 - | htsbox  samview -p - | awk '$2 == $11 && ($11 - $10) < 2  {print $1, $5
, $6, $8, $9}' > Posiciones_de_los_tags.txt

#paste 
awk 'NR==FNR{a[$1]=$0; next} {print $0, a[$1]}' name_sequence_lenght.txt Posiciones_de_los_tags.txt > Posiciones_de_los_tags_name_sequence_lenght.txt

#find the snp position inside the context sequence
 awk '{
  if ($2 == "+") {
    split($7, array, /\[/)
    letters_count = length(array[1])
  } else if ($2 == "-") {
    split($7, array, /\]/)
    letters_count = length(array[2])
  }

  print $0, letters_count
}' Posiciones_de_los_tags_name_sequence_lenght.txt  > Posiciones_de_los_tags_name_sequence_lenght_lenght_to_SNP.txt


# find SNPpos in the reference  genome

 awk '{print $0, $4 + $9 +1}' Posiciones_de_los_tags_name_sequence_lenght_lenght_to_SNP.txt  > Posiciones_de_los_tags_name_sequence_lenght_lenght_to_SNP_pos.txt

#filter the original genetic map to get the marker name, linkage group, and genetic distance
 awk -v OFS=" " -F "," '{print $4, $1, $2}' MAP_tabulee_with_raw_data_AXIOM_Infinium_buildfw.csv  | sed '1,2d' > Markers_geneticdist.txt

#merge
awk 'NR==FNR{a[$1]=$0; next} {print $0, a[$1]}' Markers_geneticdist.txt  Posiciones_de_los_tags_name_sequence_lenght_lenght_to_SNP_pos.txt  | awk '{print "\"" "XRQ" "\"", "\"" $3 "\"", "\""
$1 "\"" , $10 ,$13}' > Table_For_Marey.txt

#add header
cat Names.txt Table_For_Marey.txt > Table_For_Marey_names.txt


####################################################
######To include the HA markers
####################################################

#create fasta file

#example with another csv file

awk -F',' -v OFS="\n" '{print ">"$1, $2}' list_mk_infinium_inedi_context_sequences.csv > list_mk_infinium_inedi_context_sequences.fa
sed '/--/d' list_mk_infinium_inedi_context_sequences.fa |  sed 's/\[A\/.\]/N/g' | sed 's/\[T\/.\]/N/g' | sed 's/\[C\/.\]/N/g' | sed 's/\[G\/.\]/N/g' |  awk '/^>/ {if (seq) print seq; print; seq=""; next} {gsub(/[^AGCT]/, "N"); seq = seq $0} END {print seq}'  > list_mk_infinium_inedi_context_sequences_clean.fa

bwa mem HanXRQv2.fasta  list_mk_infinium_inedi_context_sequences_clean.fa > list_mk_infinium_inedi_context_sequences_clean.sam

samtools view -b list_mk_infinium_inedi_context_sequences_clean.sam > list_mk_infinium_inedi_context_sequences_clean.bam

samtools sort list_mk_infinium_inedi_context_sequences_clean.bam -o list_mk_infinium_inedi_context_sequences_clean_sorted.bam

# obtain leght of the context sequence
grep -v ">" list_mk_infinium_inedi_context_sequences_clean.fa | awk '{print length($0)}' > legthsHA.txt

awk '/^>/{printf "%s ",$0;next}{print}' list_mk_infinium_inedi_context_sequences.fa  > name_sequenceHA.txt

paste  -d ' '  name_sequenceHA.txt legthsHA.txt  | sed 's/>//g' >  name_sequence_lenghtHA.txt


#awk '$2 == $11  esto quiere decir que Query sequence length == Alignment block length y  ($11 - $10) < 2  quire decir que solo haya un missmatch o menos, pero como tenemos varias letras raras, debemos de tener más de un missmatch, asi que esto lo cambie a 5
  samtools calmd list_mk_infinium_inedi_context_sequences_clean_sorted.bam  HanXRQv2.fasta | samtools view -bq 50 - | htsbox  samview -p - | awk '$2 == $11 && ($11 - $10) < 7  {print $1, $5, $6, $8, $9}' > Posiciones_de_los_tags_HA.txt



  awk 'NR==FNR{a[$1]=$0; next} {print $0, a[$1]}'  name_sequence_lenghtHA.txt  Posiciones_de_los_tags_HA.txt > Posiciones_de_los_tags_name_sequence_lenght_HA.txt

  awk '{
  if ($2 == "+") {
    split($7, array, /\[/)
    letters_count = length(array[1])
  } else if ($2 == "-") {
    split($7, array, /\]/)
    letters_count = length(array[2])
  }

  print $0, letters_count
}' Posiciones_de_los_tags_name_sequence_lenght_HA.txt > Posiciones_de_los_tags_name_sequence_lenght_lenght_to_SNP_HA.txt


 awk '{print $0, $4 + $9 +1}' Posiciones_de_los_tags_name_sequence_lenght_lenght_to_SNP_HA.txt > Posiciones_de_los_tags_name_sequence_lenght_lenght_to_SNP_pos_HA.txt


 cat Posiciones_de_los_tags_name_sequence_lenght_lenght_to_SNP_pos.txt Posiciones_de_los_tags_name_sequence_lenght_lenght_to_SNP_pos_HA.txt > Posiciones_de_los_tags_name_sequence_lenght_lenght_to_SNP_pos_HA_AX.txt

  awk 'NR==FNR{a[$1]=$0; next} {print $0, a[$1]}' Markers_geneticdist.txt Posiciones_de_los_tags_name_sequence_lenght_lenght_to_SNP_pos_HA_AX.txt | awk '{print "\"" "XRQ" "\"", "\"" $3 "\"", "\"" $1 "\"" , $10 ,$13}' >  Table_For_Marey_HA_AX.tx

