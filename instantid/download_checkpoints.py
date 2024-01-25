import torch
from pipeline_stable_diffusion_xl_instantid import StableDiffusionXLInstantIDPipeline
from huggingface_hub import hf_hub_download


def fetch_instantid_checkpoints():
    """
    Fetches InstantID checkpoints from the HuggingFace model hub.
    """
    hf_hub_download(
        repo_id='InstantX/InstantID',
        filename='ControlNetModel/config.json',
        local_dir='./checkpoints',
        local_dir_use_symlinks=False
    )

    hf_hub_download(
        repo_id='InstantX/InstantID',
        filename='ControlNetModel/diffusion_pytorch_model.safetensors',
        local_dir='./checkpoints',
        local_dir_use_symlinks=False
    )

    hf_hub_download(
        repo_id='InstantX/InstantID',
        filename='ip-adapter.bin',
        local_dir='./checkpoints',
        local_dir_use_symlinks=False
    )


def fetch_pretrained_model(model_class, model_name, **kwargs):
    """
    Fetches a pretrained model from the HuggingFace model hub.
    """
    max_retries = 3
    for attempt in range(max_retries):
        try:
            return model_class.from_pretrained(model_name, **kwargs)
        except OSError as err:
            if attempt < max_retries - 1:
                print(
                    f'Error encountered: {err}. Retrying attempt {attempt + 1} of {max_retries}...')
            else:
                raise


def get_instantid_pipeline():
    """
    Fetches the InstantID pipeline from the HuggingFace model hub.
    """
    common_args = {
        'torch_dtype': torch.float16,
    }

    pipeline = fetch_pretrained_model(StableDiffusionXLInstantIDPipeline,
                                       'wangqixun/YamerMIX_v8', **common_args)

    return pipeline


if __name__ == "__main__":
    fetch_instantid_checkpoints()
    get_instantid_pipeline()

