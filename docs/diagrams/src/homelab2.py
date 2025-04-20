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

with Diagram("Homelab Network", show=False, filename="./out/homelab2"):
    with Cluster("Raspberry Pi 3B"):
        dozzle_agent_1 = Custom("Dozzle Agent", f"{icons_path}/dozzle.png")
        tvheadend = Custom("Tvheadend", f"{icons_path}/tvheadend.png")

        dozzle_agent_1 - Edge(color="transparent") - tvheadend


    with Cluster("Raspberry Pi 4B 2GB"):
        dozzle_agent_2 = Custom("Dozzle Agent", f"{icons_path}/dozzle.png")
        dwservice = Custom("DWService", f"{icons_path}/dwservice.png")

        dozzle_agent_2 - Edge(color="transparent") - dwservice

    with Cluster("Raspberry Pi 4B 4GB"):
        dozzle_agent_3 = Custom("Dozzle Agent", f"{icons_path}/dozzle.png")
        gatus_2 = Custom("Gatus 2", f"{icons_path}/gatus.png")
        motioneye = Custom("MotionEye", f"{icons_path}/motioneye.png")
        pihole_2_primary = Custom("PiHole 2 Primary", f"{icons_path}/pihole.png")
        pihole_2_secondary = Custom("PiHole 2 Secondary", f"{icons_path}/pihole.png")
        unbound_2_default = Custom("Unbound 2 Default", f"{icons_path}/unbound.png")
        unbound_2_open = Custom("Unbound 2 Open", f"{icons_path}/unbound.png")
        unifi_controller = Custom("UniFi Controller", f"{icons_path}/unifi.png")

        pihole_2_secondary - Edge(color="transparent") - unbound_2_default - Edge(color="transparent") - unbound_2_open - Edge(color="transparent") - unifi_controller
        dozzle_agent_3 - Edge(color="transparent") - gatus_2 - Edge(color="transparent") - motioneye - Edge(color="transparent") - pihole_2_primary

    with Cluster("Odroid H3"):
        actualbudget_main = Custom("ActualBudget (main)", f"{icons_path}/actualbudget.png")
        actualbudget_public = Custom("ActualBudget (public)", f"{icons_path}/actualbudget.png")
        changedetection = Custom("Changedetection", f"{icons_path}/changedetection.png")
        dockerhub_proxy = Custom("DockerHub cache proxy", f"{icons_path}/docker.png")
        docker_build = Custom("Docker Build", f"{icons_path}/docker.png")
        dozzle_agent_4 = Custom("Dozzle Agent", f"{icons_path}/dozzle.png")
        dozzle = Custom("Dozzle", f"{icons_path}/dozzle.png")
        gatus_1 = Custom("Gatus 1", f"{icons_path}/gatus.png")
        healthchecks = Custom("Healthchecks", f"{icons_path}/healthchecks.png")
        home_assistant = Custom("Home Assistant", f"{icons_path}/homeassistant.png")
        homepage = Custom("Homepage", f"{icons_path}/homepage.png")
        jellyfin = Custom("Jellyfin", f"{icons_path}/jellyfin.png")
        minio = Custom("MinIO", f"{icons_path}/minio.png")
        ntfy = Custom("Ntfy", f"{icons_path}/ntfy.png")
        omada_controller = Custom("Omada Controller", f"{icons_path}/tp-link.png")
        pihole_1_primary = Custom("PiHole 1 Primary", f"{icons_path}/pihole.png")
        pihole_1_secondary = Custom("PiHole 1 Secondary", f"{icons_path}/pihole.png")
        renovatebot = Custom("Renovatebot", f"{icons_path}/renovatebot.png")
        smtp4dev = Custom("Smtp4dev", f"{icons_path}/smtp4dev.png")
        speedtest_tracker = Custom("Speedtest Tracker", f"{icons_path}/speedtest-tracker.png")
        unbound_1_default = Custom("Unbound 1 Default", f"{icons_path}/unbound.png")
        unbound_1_open = Custom("Unbound 1 Open", f"{icons_path}/unbound.png")

        pihole_1_secondary - Edge(color="transparent") - smtp4dev - Edge(color="transparent") - Edge(color="transparent") - unbound_1_default - Edge(color="transparent") - unbound_1_open
        minio - Edge(color="transparent") - ntfy - Edge(color="transparent") - omada_controller - Edge(color="transparent") - renovatebot - Edge(color="transparent") - speedtest_tracker - Edge(color="transparent") - pihole_1_primary
        dozzle_agent_4 - Edge(color="transparent") - gatus_1 - Edge(color="transparent") - healthchecks - Edge(color="transparent") - home_assistant - Edge(color="transparent") - homepage - Edge(color="transparent") - jellyfin
        actualbudget_main - Edge(color="transparent") - actualbudget_public - Edge(color="transparent") - changedetection - Edge(color="transparent") - dockerhub_proxy - Edge(color="transparent") - docker_build - Edge(color="transparent") - dozzle
