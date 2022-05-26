#!/bin/bash
# ngc_vep

set -exo pipefail

main() {

    echo "Value of input_vcf_files: '$input_vcf_files'"
    echo "Value of input_snv_bundle: '$input_snv_bundle'"
    
    time dx-download-all-inputs --parallel
    
    mkdir -p out/outfiles
    
    #Permissions to write to /home/dnanexus
    chmod a+rwx /home/dnanexus

    #move all downloaded vcf files into folder: /snv/demo/examples/samples
    find ~/in/input_snv_bundle -type f -name "*" -print0 | xargs -0 -I {} mv {} /home/dnanexus/

    # unpack snv pipeline bundle
    tar -xzf /home/dnanexus/snv-master.tar.gz

    find ~/in/input_vcf_files -type f -name "*" -print0 | xargs -0 -I {} mv {} /home/dnanexus/snv-master/demo/example/vcf

    gunzip /home/dnanexus/snv-master/demo/example/vcf/*.gz

    #find ~/in/input_manifest_files -type f -name "*" -print0 | xargs -0 -I {} mv {} /home/dnanexus/snv-master/demo/example/manifest

    echo "files are copied"

    #install conda, create, run env
    wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda.sh

    bash ~/miniconda.sh -b -p $HOME/miniconda

    eval "$(/home/dnanexus/miniconda/bin/conda shell.bash hook)"

    conda init

    conda deactivate

    #conda config --set auto_activate_base false

    #conda

    conda env create -f /home/dnanexus/ngc_snv_env.yml

    conda activate ngc_snv
    
    #Run sv scripts
    mkdir -p /home/dnanexus/tmp_data
    ########### START: VEP Annotation #################### 
    
    echo "[`date`] Running VEP"

    vep --input_file /home/dnanexus/snv-master/demo/example/vcf/NGC00142_01.vcf --vcf -o STDOUT --format vcf --offline --cache --dir_cache /home/dnanexus/snv-master/demo/softwares/vep/grch37 --force_overwrite --species homo_sapiens --assembly GRCh37 --port 3337 --vcf_info_field ANN --sift b --polyphen b --humdiv --regulatory --allele_number --total_length --numbers --domains --hgvs --protein --symbol --ccds --uniprot --canonical --biotype --check_existing --af --af_1kg --pubmed --gene_phenotype --variant_class --plugin CADD,/home/dnanexus/snv-master/demo/resources/cadd/grch37/whole_genome_SNVs.tsv.gz,/home/dnanexus/snv-master/demo/resources/cadd/grch37/InDels.tsv.gz --plugin ExACpLI,/home/dnanexus/snv-master/demo/resources/gnomad/grch37/gnomad.v2.1.1.lof_metrics.by_transcript_forVEP.txt --plugin REVEL,/home/dnanexus/snv-master/demo/resources/revel/grch37/new_tabbed_revel.tsv.gz --plugin SpliceRegion --stats_text --stats_file /home/dnanexus/tmp_data/tmpFile_1_AC0.exon.noGT.vep_stats.txt --output_file /home/dnanexus/tmp_data/tmpFile_1_AC0.exon.noGT.new.vep.vcf

    bgzip -c /home/dnanexus/tmp_data/tmpFile_1_AC0.exon.noGT.new.vep.vcf > /home/dnanexus/tmp_data/tmpFile_1_AC0.exon.noGT.new.vep.vcf.gz

    tabix -p vcf /home/dnanexus/tmp_data/tmpFile_1_AC0.exon.noGT.new.vep.vcf.gz

    echo "[`date`] Annotating bcf with VEP results"

    bcftools annotate -c INFO/ANN -a /home/dnanexus/tmp_data/tmpFile_1_AC0.exon.noGT.new.vep.vcf.gz /home/dnanexus/tmp_data/tmpFile_1_AC0.exon.bcf -Ob -o /home/dnanexus/tmp_data/tmpFile_1_AC0.exon.vep.bcf
    bcftools index /home/dnanexus/tmp_data/tmpFile_1_AC0.exon.vep.bcf

    if [ ! -e /home/dnanexus/tmp_data/tmpFile_1_AC0.exon.vep.bcf ]; then 
    echo -e "ERROR: /home/dnanexus/tmp_data/tmpFile_1_AC0.exon.vep.bcf doesnot exist" 
    echo "0" | cat > "/home/dnanexus/snv-master/demo/example/20220214/tmp_status/Job_status_1.txt"
    exit 1
    else
          echo "1" | cat > "/home/dnanexus/snv-master/demo/example/20220214/tmp_status/Job_status_1.txt"
    fi

    ############### END: VEP Annotation  #################### 
    ########### START: Add Custom Annotations ############### 
    echo "[`date`] Adding custom annotations"

    bcftools annotate -c INFO/GNOMADg_AC:=INFO/AC,INFO/GNOMADg_AF:=INFO/AF,INFO/GNOMADg_nhomalt:=INFO/nhomalt,INFO/GNOMADg_AC_male:=INFO/AC_male,INFO/GNOMADg_AC_female:=INFO/AC_female,INFO/GNOMADg_AF_male:=INFO/AF_male,INFO/GNOMADg_AF_female:=INFO/AF_female,INFO/GNOMADg_AF_afr:=INFO/AF_afr,INFO/GNOMADg_AF_amr:=INFO/AF_amr,INFO/GNOMADg_AF_asj:=INFO/AF_asj,INFO/GNOMADg_AF_eas:=INFO/AF_eas,INFO/GNOMADg_AF_fin:=INFO/AF_fin,INFO/GNOMADg_AF_nfe:=INFO/AF_nfe,INFO/GNOMADg_AF_oth:=INFO/AF_oth,INFO/GNOMADg_AC_afr:=INFO/AC_afr,INFO/GNOMADg_AC_amr:=INFO/AC_amr,INFO/GNOMADg_AC_asj:=INFO/AC_asj,INFO/GNOMADg_AC_eas:=INFO/AC_eas,INFO/GNOMADg_AC_fin:=INFO/AC_fin,INFO/GNOMADg_AC_nfe:=INFO/AC_nfe,INFO/GNOMADg_AC_oth:=INFO/AC_oth,INFO/GNOMADg_nhomalt_afr:=INFO/nhomalt_afr,INFO/GNOMADg_nhomalt_amr:=INFO/nhomalt_amr,INFO/GNOMADg_nhomalt_asj:=INFO/nhomalt_asj,INFO/GNOMADg_nhomalt_eas:=INFO/nhomalt_eas,INFO/GNOMADg_nhomalt_fin:=INFO/nhomalt_fin,INFO/GNOMADg_nhomalt_nfe:=INFO/nhomalt_nfe,INFO/GNOMADg_nhomalt_oth:=INFO/nhomalt_oth,INFO/GNOMADg_popmax:=INFO/popmax,INFO/GNOMADg_AC_popmax:=INFO/AC_popmax,INFO/GNOMADg_AN_popmax:=INFO/AN_popmax,INFO/GNOMADg_AF_popmax:=INFO/AF_popmax -a /home/dnanexus/snv-master/demo/resources/gnomad/grch37/gnomad.genomes.r2.1.1.sites.vcf.bgz -r 1 /home/dnanexus/tmp_data/tmpFile_1_AC0.exon.vep.bcf -Ob -o /home/dnanexus/tmp_data/tmpFile_1_AC0.exon.vep.tmp.bcf
    mv -f /home/dnanexus/tmp_data/tmpFile_1_AC0.exon.vep.tmp.bcf /home/dnanexus/tmp_data/tmpFile_1_AC0.exon.vep.anno.bcf
    bcftools index -f /home/dnanexus/tmp_data/tmpFile_1_AC0.exon.vep.anno.bcf

    bcftools annotate -c INFO/GNOMADe_AC:=INFO/AC,INFO/GNOMADe_AF:=INFO/AF,INFO/GNOMADe_nhomalt:=INFO/nhomalt,INFO/GNOMADe_AC_male:=INFO/AC_male,INFO/GNOMADe_AC_female:=INFO/AC_female,INFO/GNOMADe_AF_male:=INFO/AF_male,INFO/GNOMADe_AF_female:=INFO/AF_female,INFO/GNOMADe_AF_afr:=INFO/AF_afr,INFO/GNOMADe_AF_amr:=INFO/AF_amr,INFO/GNOMADe_AF_asj:=INFO/AF_asj,INFO/GNOMADe_AF_eas:=INFO/AF_eas,INFO/GNOMADe_AF_fin:=INFO/AF_fin,INFO/GNOMADe_AF_nfe:=INFO/AF_nfe,INFO/GNOMADe_AF_oth:=INFO/AF_oth,INFO/GNOMADe_AF_sas:=INFO/AF_sas,INFO/GNOMADe_AC_afr:=INFO/AC_afr,INFO/GNOMADe_AC_amr:=INFO/AC_amr,INFO/GNOMADe_AC_asj:=INFO/AC_asj,INFO/GNOMADe_AC_eas:=INFO/AC_eas,INFO/GNOMADe_AC_fin:=INFO/AC_fin,INFO/GNOMADe_AC_nfe:=INFO/AC_nfe,INFO/GNOMADe_AC_oth:=INFO/AC_oth,INFO/GNOMADe_AC_sas:=INFO/AC_sas,INFO/GNOMADe_nhomalt_afr:=INFO/nhomalt_afr,INFO/GNOMADe_nhomalt_amr:=INFO/nhomalt_amr,INFO/GNOMADe_nhomalt_asj:=INFO/nhomalt_asj,INFO/GNOMADe_nhomalt_eas:=INFO/nhomalt_eas,INFO/GNOMADe_nhomalt_fin:=INFO/nhomalt_fin,INFO/GNOMADe_nhomalt_nfe:=INFO/nhomalt_nfe,INFO/GNOMADe_nhomalt_oth:=INFO/nhomalt_oth,INFO/GNOMADe_nhomalt_sas:=INFO/nhomalt_sas,INFO/GNOMADe_popmax:=INFO/popmax,INFO/GNOMADe_AC_popmax:=INFO/AC_popmax,INFO/GNOMADe_AN_popmax:=INFO/AN_popmax,INFO/GNOMADe_AF_popmax:=INFO/AF_popmax -a /home/dnanexus/snv-master/demo/resources/gnomad/grch37/gnomad.exomes.r2.1.1.sites.vcf.bgz -r 1 /home/dnanexus/tmp_data/tmpFile_1_AC0.exon.vep.anno.bcf -Ob -o /home/dnanexus/tmp_data/tmpFile_1_AC0.exon.vep.tmp.bcf
    mv -f /home/dnanexus/tmp_data/tmpFile_1_AC0.exon.vep.tmp.bcf /home/dnanexus/tmp_data/tmpFile_1_AC0.exon.vep.anno.bcf
    bcftools index -f /home/dnanexus/tmp_data/tmpFile_1_AC0.exon.vep.anno.bcf

    bcftools annotate -c INFO/EXAC_AC,INFO/EXAC_AC_AFR,INFO/EXAC_AC_AMR,INFO/EXAC_AC_EAS,INFO/EXAC_AC_FIN,INFO/EXAC_AC_NFE,INFO/EXAC_AC_OTH,INFO/EXAC_AC_SAS,INFO/EXAC_AC_Hemi,INFO/EXAC_AC_Hom,INFO/EXAC_Hom_AFR,INFO/EXAC_AF,INFO/EXAC_AC_MALE,INFO/EXAC_AC_FEMALE,INFO/EXAC_AC_POPMAX,INFO/EXAC_AN_POPMAX -a /home/dnanexus/snv-master/demo/resources/exac/grch37/ExAC.r0.3.1.sites.vep.decompose.norm.prefixed_PASS-only.vcf.gz -r 1 /home/dnanexus/tmp_data/tmpFile_1_AC0.exon.vep.anno.bcf -Ob -o /home/dnanexus/tmp_data/tmpFile_1_AC0.exon.vep.tmp.bcf
    mv -f /home/dnanexus/tmp_data/tmpFile_1_AC0.exon.vep.tmp.bcf /home/dnanexus/tmp_data/tmpFile_1_AC0.exon.vep.anno.bcf
    bcftools index -f /home/dnanexus/tmp_data/tmpFile_1_AC0.exon.vep.anno.bcf

    bcftools annotate -c INFO/EXAC_Hom_AMR:=INFO/Hom_AMR,INFO/EXAC_Hom_EAS:=INFO/Hom_EAS,INFO/EXAC_Hom_FIN:=INFO/Hom_FIN,INFO/EXAC_Hom_NFE:=INFO/Hom_NFE,INFO/EXAC_Hom_OTH:=INFO/Hom_OTH,INFO/EXAC_Hom_SAS:=INFO/Hom_SAS,INFO/EXAC_POPMAX:=INFO/POPMAX -a /home/dnanexus/snv-master/demo/resources/exac/grch37/ExAC.r0.3.1.sites.vep.decompose.norm.prefixed_PASS-only.vcf.gz -r 1 /home/dnanexus/tmp_data/tmpFile_1_AC0.exon.vep.anno.bcf -Ob -o /home/dnanexus/tmp_data/tmpFile_1_AC0.exon.vep.tmp.bcf
    mv -f /home/dnanexus/tmp_data/tmpFile_1_AC0.exon.vep.tmp.bcf /home/dnanexus/tmp_data/tmpFile_1_AC0.exon.vep.anno.bcf
    bcftools index -f /home/dnanexus/tmp_data/tmpFile_1_AC0.exon.vep.anno.bcf

    bcftools annotate -c INFO -a /home/dnanexus/snv-master/demo/resources/clinvar/grch37/clinvar_20200506.vcf.gz -r 1 /home/dnanexus/tmp_data/tmpFile_1_AC0.exon.vep.anno.bcf -Ob -o /home/dnanexus/tmp_data/tmpFile_1_AC0.exon.vep.tmp.bcf
    mv -f /home/dnanexus/tmp_data/tmpFile_1_AC0.exon.vep.tmp.bcf /home/dnanexus/tmp_data/tmpFile_1_AC0.exon.vep.anno.bcf
    bcftools index -f /home/dnanexus/tmp_data/tmpFile_1_AC0.exon.vep.anno.bcf

    bcftools convert -O v -o /home/dnanexus/out/outfiles/input.vep.anno.vcf /home/dnanexus/tmp_data/tmpFile_1_AC0.exon.vep.anno.bcf

    #copy results files to home upload dir
    #cp -r /home/dnanexus/snv-master/demo/examples/20220301/fam_filter/* /home/dnanexus/out/outfiles/
    
    conda deactivate
    
    # upload output 
    dx-upload-all-outputs --parallel
}
