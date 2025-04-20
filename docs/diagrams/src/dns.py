from diagrams import Cluster, Diagram, Edge, Node
from diagrams.custom import Custom

icons_path = "../icons"
common_node_attributes = {
    "labelloc": "b",
    "width": "2",
    "height": "3",
    "fixedsize": "true",
    "imagescale": "true",
}

with Diagram("Homelab Network", show=False, filename="./out/dns"):
    with Cluster("Raspberry Pi 4B 4GB"):
        with Cluster("Pihole 2"):
            pihole_2_primary = Custom("PiHole 2 Primary", f"{icons_path}/pihole.png")
            pihole_2_secondary = Custom("PiHole 2 Secondary", f"{icons_path}/pihole.png")
        with Cluster("Unbound 2"):
            unbound_2_default = Custom("Unbound 2 Default", f"{icons_path}/unbound.png")
            unbound_2_open = Custom("Unbound 2 Open", f"{icons_path}/unbound.png")

        pihole_2_primary - Edge(color="transparent") - pihole_2_secondary
        unbound_2_default - Edge(color="transparent") - unbound_2_open

    with Cluster("Odroid H3"):
        with Cluster("Pihole 1"):
            pihole_1_primary = Custom("PiHole 1 Primary", f"{icons_path}/pihole.png")
            pihole_1_secondary = Custom("PiHole 1 Secondary", f"{icons_path}/pihole.png")
            pihole_1_primary - Edge(color="transparent") - pihole_1_secondary
        with Cluster("Unbound 1"):
            unbound_1_default = Custom("Unbound 1 Default", f"{icons_path}/unbound.png")
            unbound_1_open = Custom("Unbound 1 Open", f"{icons_path}/unbound.png")
            unbound_1_default - Edge(color="transparent") - unbound_1_open

    personal_devices = Custom("Personal Devices", f"{icons_path}/personal-devices.png", **common_node_attributes)
    # monika_devices = Custom("Monika's Devices", f"{icons_path}/personal-devices.png", **common_node_attributes)

    unbounds_default = [unbound_1_default, unbound_2_default]
    unbounds_open = [unbound_1_open, unbound_2_open]
    piholes = [pihole_1_primary, pihole_2_primary, pihole_1_secondary, pihole_2_secondary]

    personal_devices >> unbounds_default
    # monika_devices >> unbounds_open
    for unbound in [*unbounds_default, *unbounds_open]:
        unbound >> piholes
