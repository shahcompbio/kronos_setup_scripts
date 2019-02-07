import os
import re
import sys
import pysam
import logging
import subprocess
import pandas as pd

logging.basicConfig(format="%(asctime)s - %(levelname)s - %(message)s", stream=sys.stderr, level=logging.INFO)

REF_GENOME_MAP = {
    'HG18': [r'hg[-_ ]?18',                
             r'ncbi[-_ ]?build[-_ ]?36.1',  
            ],
    'HG19': [r'hg[-_ ]?19',                
             r'grc[-_ ]?h[-_ ]?37',        
             r'ncbi[-_ ]?build[-_ ]?37'
            ],}


def check_bam(df):
    df["bam"] = df["ABSOLUTE_FILE_PATH"]
    cmd = [
        "samtools",
        "quickcheck",
        df["ABSOLUTE_FILE_PATH"]
    ]
    
    #Check if that bam has an EOF
    try:
        subprocess.check_call(cmd)
        df["bad_bam"] = ""
    except:
        logging.warning("The bam {} needs to be checked".format(df["ABSOLUTE_FILE_PATH"]))
        df["bad_bam"] = "TRUE"

    #Check that the reference genome is HG19
    bam_header = pysam.AlignmentFile(df["ABSOLUTE_FILE_PATH"]).header

    try:
        sq_as = bam_header["SQ"][0]["AS"]
    except KeyError:
        sq_as = None
    found_match = False

    if sq_as:
        for ref, regex_list in REF_GENOME_MAP.iteritems():
            for regex in regex_list:
                if re.search(regex, sq_as, flags=re.I):
                    #Found a match
                    reference_genome = ref
                    found_match = True
                    break

            if found_match:
                break 

    if not found_match:
        logging.error("Unrecogized reference genome {} for {}".format(sq_as, df["ABSOLUTE_FILE_PATH"]))
        df["bad_genome"] = "TRUE"
    elif reference_genome == "HG18":
        logging.warning("Reference genome for {} is HG18".format(df["ABSOLUTE_FILE_PATH"]))
        df["bad_genome"] = "TRUE"
    else:
        df["bad_genome"] = ""


    #Check that bai exists
    if not os.path.isfile(str(df["ABSOLUTE_FILE_PATH"]) + ".bai"):
        logging.warning("The bai file does not exist for {}. Please index this bam".format(df["ABSOLUTE_FILE_PATH"]))
        df["no_bai"] = "TRUE"
    else:
        df["no_bai"] = ""

    return df[["bam", "bad_bam", "bad_genome", "no_bai"]]


if __name__=='__main__':
    df = pd.read_csv(sys.argv[1])
    output = sys.argv[2]

    df_checked = df.apply(check_bam, axis=1)
    df_checked.to_csv(output, index=False)





