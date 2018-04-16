#!/bin/csh -ex
# Modify below to run subsets of all subjects
set SubList = ("0406")
# Modify below to run subsets of all subjects
#set SubList = ("S54" "S55" "S56" "S57" "S53")
# Modify below to run all subjects
#set SubList = ("S01" "S02" "S03" "S04" "S05" "S06" "S07" "S09" "S10" "S11" "S12" "S13" "S14" "S15" "S16" "S17" "S18" "S19" "S20" "S21" "S22" "S23" "S24" "S25" "S26" "S27" "S28" "S29" "S30" "S31" "S32" "S33" "S34" "S35" "S36" "S37" "S38" "S39" "S40" "S41" "S42" "S43" "S44" "S45" "S46" "S47" "S48" "S49" "S50" "S51" "S52" "S53" "S54" "S55" "S56" "S57")
# echo SubList is $SubList
### Works on Pokemon and Totoro
### For each study, you probably need to reset the TR, number of slices and number of volumes
### For each subject/scan, modify this script to set the locations of your EPI and Anat DICOM files
### Run via-- tcsh Sele_Functional_QC_kk_PRF_clean.sh
# SELE to access pokemon and run from there ssh -Y schintus2ATpokemon data are in shares/BNU/EXP2_PRF/QC_PRF_Folder
### Quality Control script for functional data
### Created by Michael Freedberg. Modified by Kris Knutson. Mike added # Create Automask, 3dAutomask -prefix Mask_anat MPRAGE_al_junk+orig. lines
### This script is designed to take the raw dicom epi file and output specific imaging quality metrics for motion, dvars, smoothness, tsd, tsnr.
### This script DOES NOT tell you if the output values are bad.

#echo Hostname is `hostname`
if ( `hostname` == "ndsw-bnu-pokemon.ninds.nih.gov") then
   set hostpath = "/net/nindsdirfs.ninds.nih.gov/ifs/shares/BNU"
else if (`hostname` == "ndsw-bnu-totoro.ninds.nih.gov" ) then
   set hostpath = "/net/nindsdirfs.ninds.nih.gov/ifs/shares/BNU"
else
   set hostpath = "/Volumes/Shares/BNU"
endif

# Path to anatomical dataset
set anatpath = "${hostpath}/cnsraid/schintu/data_analysis/EXP3_RS"
echo anatpath is $anatpath

# Path to Folder where you want QC files to be dumped. Main QC folder must already exist
set QC_Folder = "${hostpath}/cnsraid/schintu/data_analysis/EXP3_RS/QC_EXP_3/0406_mr_0003"
echo QC_Folder is $QC_Folder

##### Set initial parameters ######
# Temporary name of Anat files (not important)
set AName = mprage
# Temporary name of EPI files (not important)
set FName = OutBrick
# Condition of run
set scan = TECH

# TR of EPI data
set TR = 2.500
# Number of Slices per volume (are those the images ACQUISITION IN THE README FILE ??? )
set slices = 45
# Number of Dicom files
set filenum = 240

### Set drive locations
foreach Subject ($SubList)
    echo Subject is $Subject

# Set AnatRun
    if ($Subject == S01 || $Subject == S02 || $Subject == S03 || $Subject == S04 || $Subject == S05) then
        set Anat_Drive = ${anatpath}/${Subject}/mr_0006
    else if ($Subject == S15 || $Subject == S16 || $Subject == S17 || $Subject == S18 || $Subject == S45 || $Subject == S54) then
        set Anat_Drive = ${anatpath}/${Subject}/mr_0015
    else if ($Subject == S08 || $Subject == S21 || $Subject == S35) then
        set Anat_Drive = ${anatpath}/${Subject}/mr_0016
    else if ($Subject == S20 || $Subject == S37 || $Subject == S42) then
        set Anat_Drive = ${anatpath}/${Subject}/mr_0018
    else if ($Subject == S56) then
        set Anat_Drive = ${anatpath}/${Subject}/mr_0019
    else if ($Subject == S89) then
        set Anat_Drive = ${anatpath}/${Subject}/mr_40005
    else if ($Subject == "0406") then
        set Anat_Drive = "${anatpath}/VOLUNTEER_TECHNICAL-20180406/20180406-26331/mr_0005"
    else
        echo "Warning- Anat_Drive not set. Subject ${Subject} not specified"
    endif

        echo xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
        echo "WARNING YOU ARE ABOUT TO ERASE EVERYTHING in ${QC_Folder}/${Subject} if it exists"
        echo          Hit Enter to Proceed or CTRL-C to abort
        echo xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
        set req = $<

        echo Using Subject = $Subject, TR of $TR, Num of slices = $slices, Num of volumes = $filenum
        cd $QC_Folder
        if (! -d $Subject) then
            echo xxxxxxxxxxxxxxxxxxxxxxxxxx
            echo Creating subject directory
            echo xxxxxxxxxxxxxxxxxxxxxxxxxx
            mkdir $Subject
            cd $Subject
            echo xxxxxxxxxxxxxxxxxxxxxxxxx
            echo Creating Output directory
            echo xxxxxxxxxxxxxxxxxxxxxxxxx
            mkdir Output
        else
            cd $Subject
            rm *.BRIK
            rm *.HEAD
            rm *.txt
            rm *.1D
            if (-d Output) then
                cd ./Output
                rm *.txt
                rm *.1D
                rm *.png
                cd ..
            else
               mkdir Output
            endif
        endif

        # ============================ to3d ============================
        echo xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
        echo   Converting DICOMs to afni format for subject ${Subject}
        echo xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
        #anat
        ### May need to change infile_prefix in line below depending on name of anatomical dicom files
        if (! -f ${Anat_Drive}/${AName}+orig.BRIK ) then
            Dimon -infile_prefix ${Anat_Drive}/anat_t1w_mp_rage_1mm_pure -dicom_org -use_obl_origin -GERT_Reco -gert_create_dataset -gert_to3d_prefix ${AName} -gert_outdir ${QC_Folder}/$Subject/ -quit
        ###        to3d -prefix ${AName} -@< dimon.files.run.*
        ###        3dcopy $AName+orig. ${QC_Folder}/$Subject/
        else
            echo ${AName}+orig already exists in $Anat_Drive. Copying to QC_Folder $QC_Folder/${Subject}
            3dcopy ${Anat_Drive}/${AName}+orig. ${QC_Folder}/$Subject/
        endif
        ###to3d -anat -assume_dicom_mosaic -prefix ${AName} ${ADrive}/*.dcm

# Make list of MR folders for this subject
        set PRF_Drive = "${hostpath}/cnsraid/schintu/data_analysis/EXP3_RS/VOLUNTEER_TECHNICAL-20180406/20180406-26331"
        cd $PRF_Drive
        ls -d mr_0003/ | cut -f1 -d'/' > dir.txt
        setenv dir_list `cat dir.txt`
        foreach dir ( $dir_list )
            #epi
            cd $PRF_Drive/$dir
            if (! -f "${FName}+orig.BRIK") then
                Dimon -infile_pattern '*.dcm' -assume_dicom_mosaic -use_obl_origin -order_as_zt -nt ${filenum} -gert_nz ${slices} -tr ${TR} -dicom_org -GERT_Reco -gert_create_dataset -gert_to3d_prefix ${dir}_${FName} -gert_outdir ${QC_Folder}/${Subject} -quit
            else
                echo "$FName+orig.BRIK already exists in ${dir}. Copying to QC_Folder/Subject_folder ${QC_Folder}/${Subject}"
                3dcopy ${FName}+orig.BRIK ${QC_Folder}/${Subject}/${dir}_${FName}+orig.
            endif
            cd ${QC_Folder}/${Subject}
            if (-e ${dir}_${FName}+orig.BRIK) then
               echo ${dir}_${FName}+orig.BRIK exists in ${QC_Folder}/${Subject}
            else                
              echo xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
              echo AFNI RESTING STATE FILE NOT CREATED
              echo xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
            endif
        end
        # ============================ Skullstrip ============================
        echo xxxxxxxxxxxxxxxxxx
        echo   3dUnifizing and Skullstripping MPRAGE and creating brain mask
        echo xxxxxxxxxxxxxxxxxx
        ### Perform Skull Strip on MPRAGE ###
        3dWarp -deoblique -prefix ${AName}_deob+orig. ${AName}+orig.
        3dUnifize -prefix afni.MPRAGE ${AName}_deob+orig.
        ### NOTE: If you get an error here regarding DYLD_LIBRARY_PATH, see https://afni.nimh.nih.gov/afni/community/board/read.php?1,144328,144475#msg-144475
        3dSkullStrip -input ${AName}_deob+orig. -avoid_vent -touchup -touchup -push_to_edge \
        -init_radius 100 -ld 30 -niter 250 -shrink_fac 0.6 -shrink_fac_bot_lim 0.65 \
        -smooth_final 30 -max_inter_iter 2 -fill_hole 15 -mask_vol -prefix ${AName}_amask
        3dcalc -a ${AName}_amask+orig. -expr "step(a-4)" -prefix ss.brainmask+orig
        3dmask_tool -input ss.brainmask+orig -dilate_input 6 -6 -prefix ss.brain
        3dcalc -a afni.MPRAGE+orig -b ss.brain+orig -expr "a*step(b)" -prefix ${AName}_ss
        3dAutomask ${AName}_ss+orig.

        # ============================ auto block: tcat ============================
        foreach dir ( $dir_list )
            echo xxxxxxxxxxxxxxxxxx
            echo  "Removing initial volumes (optional) and creating slice_timing.txt"
            echo xxxxxxxxxxxxxxxxxx
        ### Remove initial TRs for steady-state calibration
            3dTcat -prefix pb00.$Subject.$dir.$scan.tcat ${dir}_${FName}+orig.'[2..$]'
            3dinfo -verb -slice_timing pb00.$Subject.$dir.$scan.tcat+orig > slice_timing.$dir.txt
            # ================================= tshift =================================
            echo xxxxxxxxxxxxxxxxxx
            echo   Time shifting
            echo xxxxxxxxxxxxxxxxxx
            ### tshift so all slice timing is the same
            3dTshift -tzero 0 -quintic -prefix pb00.$Subject.$dir.$scan.tshift pb00.$Subject.$dir.$scan.tcat+orig.
            3dWarp -deoblique -prefix pb01.$Subject.$dir.$scan.tshift pb00.$Subject.$dir.$scan.tshift+orig

            # ================================= volreg =================================
            echo xxxxxxxxxxxxxxxxxx
            echo   Volume registering. Creates dfile.scan.1D, which is added to dfile_rall.1D, mat.scan.vr.aff12.1D
            echo xxxxxxxxxxxxxxxxxx
            # Volreg
            3dvolreg -verbose -zpad 1 -cubic -base pb01.$Subject.$dir.$scan.tshift+orig'[0]'    \
            -1Dfile dfile.$dir.$scan.1D -1Dmatrix_save mat.$dir.$scan.vr.aff12.1D             \
            -prefix pb02.$Subject.$dir.$scan.volreg+orig pb01.$Subject.$dir.$scan.tshift+orig
            # make a single file of registration params
            cat dfile.$dir.$scan.1D > dfile_rall.1D

            # ================================= align ==================================
            echo xxxxxxxxxxxxxxxxxx
            echo   Aligning
            echo xxxxxxxxxxxxxxxxxx
            # for e2a: compute anat alignment transformation to EPI registration base
            align_epi_anat.py -anat2epi -anat ${AName}_ss+orig. -anat_has_skull no \
            -epi pb02.$Subject.$dir.$scan.volreg+orig -epi_base 2 -epi_strip 3dAutomask \
            -suffix _${dir}_al_junk -check_flip -volreg off -tshift off \
            -ginormous_move -cost lpc+ZZ
            # ================================= Unifize ==================================
            echo xxxxxxxxxxxxxxxxxx
            echo   Unifizing EPI
            echo xxxxxxxxxxxxxxxxxx
            # normalize intensity to mean of 10000
            3dUnifize -prefix $Subject.$dir.$scan.Intensity_Norm1000 -EPI -input pb02.$Subject.$dir.$scan.volreg+orig
            3dcalc -a $Subject.$dir.$scan.Intensity_Norm1000+orig. -expr 'a*10' -prefix $Subject.$dir.$scan.Intensity_Norm10000+orig.

            # ================================= QC ==================================
            echo xxxxxxxxxxxxxxxxxx
            echo   Beginning QC for $Subject/$dir
            echo xxxxxxxxxxxxxxxxxx
	    # Create Automask-- added by Mike F.
	    3dAutomask -prefix Mask_anat mprage_ss_${dir}_al_junk+orig.BRIK
            # Resample mask to EPI grid-- modified to use Mask_anat rather than automask+orig.
            3dresample -input Mask_anat+orig. -master ${Subject}.${dir}.${scan}.Intensity_Norm10000+orig. -prefix Mask_Resample.$dir

            # Generate Relative Motion Value
            @1dDiffMag dfile.${dir}.${scan}.1D > Output/${dir}.RelMotion.txt

            #tSD
            3dTstat -stdev -prefix ${Subject}.${dir}.${scan}.SD ${Subject}.${dir}.${scan}.Intensity_Norm10000+orig.
            3dBrickStat -mean -mask Mask_Resample.${dir}+orig. ${Subject}.${dir}.${scan}.SD+orig. > Output/OutputtSD.${dir}.txt

            #tSNR with no preprocessing (np) other than dropping first few volumes, slice timing correction and volume registration
            3dTstat -mean -stdev -prefix np_${Subject}.${dir}.${scan}.stats pb02.$Subject.$dir.$scan.volreg+orig.
            3dcalc -a np_${Subject}.${dir}.${scan}.stats+orig.'[0]' -b np_${Subject}.${dir}.${scan}.stats+orig.'[1]' -float -expr 'a/b' -prefix np_${Subject}.${dir}.${scan}.tSNR
            3dresample -master pb02.$Subject.$dir.$scan.volreg+orig. -prefix np_${AName}_ss -inset ${AName}_ss+orig. -rmode NN
            3dBrickStat -mean -mask np_${AName}_ss+orig. np_${Subject}.${dir}.${scan}.tSNR+orig. > Output/np_${dir}.tSNR.txt

            #tSNR after preprocessing
            3dTstat -mean -stdev -prefix ${Subject}.${dir}.${scan}.stats ${Subject}.${dir}.${scan}.Intensity_Norm10000+orig.
	    # Brik[0] is mean; Brik[1] is std dev below
            3dcalc -a ${Subject}.${dir}.${scan}.stats+orig.'[0]' -b ${Subject}.$dir.$scan.stats+orig.'[1]' -float -expr 'a/b' -prefix ${Subject}.$dir.$scan.tSNR
            3dBrickStat -mean -mask Mask_Resample.${dir}+orig. ${Subject}.${dir}.${scan}.tSNR+orig. > Output/${dir}.tSNR.txt

            #Smoothness
            3dFWHMx  -mask Mask_Resample.${dir}+orig.  -detrend -ACF Output/3dFWHMx.${Subject}.${dir}.${scan}.1D -input ${Subject}.${dir}.${scan}.Intensity_Norm10000+orig.
            #DVars
            3dTto1D -input ${Subject}.${dir}.${scan}.Intensity_Norm10000+orig. -mask Mask_Resample.${dir}+orig. -method dvars -prefix EPI_DVars.${dir}.txt
            awk '{ total += $1 } END { print total/NR }' EPI_DVars.${dir}.txt > Output/DVars.${dir}.txt

            echo xxxxxxxxxxxxxxxxxx
            echo   Plot Motion. Close plot to continue
            echo xxxxxxxxxxxxxxxxxx
#           1dplot dfile.${dir}.${scan}.1D

            echo xxxxxxxxxxxxxxxxxx
            echo   Plot change in Bold RMS. Close plot to continue
            echo xxxxxxxxxxxxxxxxxx
#           1dplot EPI_DVars.${dir}.txt

            echo xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
            echo QA finished for $Subject for ${dir}
            echo xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

    end
end

 
