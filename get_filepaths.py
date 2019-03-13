import sys
import click
import logging

import pandas as pd
from dbclients.tantalus import TantalusApi

logging.basicConfig(format="%(asctime)s - %(levelname)s - %(message)s", stream=sys.stderr, level=logging.INFO)


#Query by sample ID
def get_sample_dataset(sample_id, tantalus_api):
    sequence_datasets = list(tantalus_api.list(
                "sequence_dataset",
                sample__sample_id=sample_id,
                library__library_type__name="WGS",
                reference_genome__name="HG19",
        ))

    return sequence_datasets


#Query by library ID
def get_library_dataset(library_id, tantalus_api):
    sequence_datasets = list(tantalus_api.list(
                "sequence_dataset",
                library__library_id=library_id,
                library__library_type__name="WGS",
                reference_genome__name="HG19",
        ))

    return sequence_datasets


def get_filepath(df, tantalus_api, col_name):
    if col_name == "library_id":
        sequence_datasets = get_library_dataset(df["library_id"], tantalus_api)
    elif col_name == "sample_id":
        sequence_datasets = get_sample_dataset(df["sample_id"], tantalus_api)

    most_lanes = 0
    dataset = None
    for sequence_dataset in sequence_datasets:
        #Check for datasets that have either a complete set of lanes, or have the most number of lanes
        if sequence_dataset["is_complete"]:
            dataset = sequence_dataset
        elif len(sequence_dataset["sequence_lanes"]) > most_lanes:
            dataset = sequence_dataset
            most_lanes = len(sequence_dataset["sequence_lanes"])

    if not dataset:
        logging.error("No dataset found for {}".format(df["sample_id"]))
    else:
        for resource_id in dataset["file_resources"]:
            resource = tantalus_api.get(
                    "file_resource",
                    id=resource_id
            )

            if resource["file_type"] == "BAM":
                for instance in resource["file_instances"]:
                    if instance["storage"]["name"] == "shahlab":
                        df["shahlab_path"] = instance["filepath"]
                    elif instance["storage"]["storage_type"] == "blob":
                        df["blob_path"] = instance["filepath"]
                    elif instance["storage"]["name"] == "rocks":
                        df["rocks_path"] = instance["filepath"]

    return df


@click.command()
@click.argument("ids", nargs=1)
@click.argument("id_type", type=click.Choice(['sample', 'library']), nargs=1)
@click.argument("output_file", nargs=1)
def main(**kwargs):
    try:
        df = pd.read_csv(kwargs["ids"])
    except IOError:
        raise Exception("The file {} could not be opened for reading".format(kwargs["sample_ids"]))

    tantalus_api = TantalusApi()
    
    col_name = kwargs["id_type"] + "_id"
    df = df.apply(get_filepath, args=(tantalus_api, col_name, ), axis=1)

    df[[col_name, "shahlab_path", "blob_path", "rocks_path"]].to_csv(kwargs["output_file"], index=False)


if __name__=='__main__':
    main()
