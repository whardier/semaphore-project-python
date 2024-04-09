from importlib.metadata import EntryPoint, entry_points
from typing import Iterator


def find_all_entrypoints_for_group(group: str) -> Iterator[EntryPoint]:
    for entry_point in entry_points(group=group):
        yield entry_point


if __name__ == "__main__":
    for entry_point in find_all_entrypoints_for_group("semaphore.backends"):
        print(entry_point)
        module = entry_point.load()
        print(module)
