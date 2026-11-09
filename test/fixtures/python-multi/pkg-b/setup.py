from setuptools import setup

setup(
    name="demo-b",
    version="1.0.0", # managed by updgitver
    packages=["pkg_b"],
    install_requires=[
        "demo-a==1.0.0", # managed by updgitver
    ],
)
