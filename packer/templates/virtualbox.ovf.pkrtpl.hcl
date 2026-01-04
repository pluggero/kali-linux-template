<?xml version="1.0"?>
<Envelope ovf:version="1.0" xml:lang="en-US" xmlns="http://schemas.dmtf.org/ovf/envelope/1" xmlns:ovf="http://schemas.dmtf.org/ovf/envelope/1" xmlns:rasd="http://schemas.dmtf.org/wbem/wscim/1/cim-schema/2/CIM_ResourceAllocationSettingData" xmlns:vssd="http://schemas.dmtf.org/wbem/wscim/1/cim-schema/2/CIM_VirtualSystemSettingData" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:vbox="http://www.virtualbox.org/ovf/machine">
  <References>
    <File ovf:id="file1" ovf:href="${vm_name}.vmdk"/>
  </References>
  <DiskSection>
    <Info>List of the virtual disks</Info>
    <Disk ovf:capacity="${vm_disk_size}" ovf:diskId="vmdisk1" ovf:fileRef="file1" ovf:format="http://www.vmware.com/interfaces/specifications/vmdk.html#streamOptimized" vbox:uuid="f4582d13-07af-4392-bc84-2abfcc0eee81"/>
  </DiskSection>
  <NetworkSection>
    <Info>Logical networks used in the package</Info>
    <Network ovf:name="Bridged">
      <Description>Logical network used by this appliance.</Description>
    </Network>
  </NetworkSection>
  <VirtualSystem ovf:id="${vm_name}">
    <Info>A virtual machine</Info>
    <Name>${vm_name}</Name>
    <OperatingSystemSection ovf:id="96">
      <Info>The kind of installed guest operating system</Info>
      <Description>Debian_64</Description>
    </OperatingSystemSection>
    <VirtualHardwareSection>
      <Info>Virtual hardware requirements</Info>
      <System>
        <vssd:ElementName>Virtual Hardware Family</vssd:ElementName>
        <vssd:InstanceID>0</vssd:InstanceID>
        <vssd:VirtualSystemIdentifier>${vm_name}</vssd:VirtualSystemIdentifier>
        <vssd:VirtualSystemType>virtualbox-2.2</vssd:VirtualSystemType>
      </System>
      <Item>
        <rasd:Caption>${vm_cpu_core} virtual CPU</rasd:Caption>
        <rasd:Description>Number of virtual CPUs</rasd:Description>
        <rasd:ElementName>${vm_cpu_core} virtual CPU</rasd:ElementName>
        <rasd:InstanceID>1</rasd:InstanceID>
        <rasd:ResourceType>3</rasd:ResourceType>
        <rasd:VirtualQuantity>${vm_cpu_core}</rasd:VirtualQuantity>
      </Item>
      <Item>
        <rasd:AllocationUnits>MegaBytes</rasd:AllocationUnits>
        <rasd:Caption>${vm_mem_size} MB of memory</rasd:Caption>
        <rasd:Description>Memory Size</rasd:Description>
        <rasd:ElementName>${vm_mem_size} MB of memory</rasd:ElementName>
        <rasd:InstanceID>2</rasd:InstanceID>
        <rasd:ResourceType>4</rasd:ResourceType>
        <rasd:VirtualQuantity>${vm_mem_size}</rasd:VirtualQuantity>
      </Item>
      <Item>
        <rasd:Address>0</rasd:Address>
        <rasd:Caption>sataController0</rasd:Caption>
        <rasd:Description>SATA Controller</rasd:Description>
        <rasd:ElementName>sataController0</rasd:ElementName>
        <rasd:InstanceID>3</rasd:InstanceID>
        <rasd:ResourceSubType>AHCI</rasd:ResourceSubType>
        <rasd:ResourceType>20</rasd:ResourceType>
      </Item>
      <Item>
        <rasd:AddressOnParent>0</rasd:AddressOnParent>
        <rasd:ElementName>disk1</rasd:ElementName>
        <rasd:HostResource>ovf:/disk/vmdisk1</rasd:HostResource>
        <rasd:InstanceID>4</rasd:InstanceID>
        <rasd:Parent>3</rasd:Parent>
        <rasd:ResourceType>17</rasd:ResourceType>
      </Item>
    </VirtualHardwareSection>
    <vbox:Machine ovf:required="false" version="1.19-linux" OSType="Debian_64" name="${vm_name}"  snapshotFolder="Snapshots" uuid="{0cc19ee9-dbb3-4e19-a4da-8c1911046394}">
      <ovf:Info>Complete VirtualBox machine configuration in VirtualBox format</ovf:Info>
      <Hardware>
        <Memory RAMSize="${vm_mem_size}"/>
        <Display controller="${vbox_graphics_controller}" VRAMSize="${vbox_vram}" accelerate3D="${vbox_accelerate_3d}"/>
        <Firmware type="${vbox_firmware_type}"/>
        <Boot>
          <Order position="1" device="HardDisk"/>
          <Order position="2" device="None"/>
          <Order position="3" device="None"/>
          <Order position="4" device="None"/>
        </Boot>
        <BIOS>
          <IOAPIC enabled="true"/>
          <SmbiosUuidLittleEndian enabled="true"/>
          <AutoSerialNumGen enabled="true"/>
        </BIOS>
        <Network>
          <Adapter slot="0" enabled="true" MACAddress="080027DDE185" type="82540EM">
            <DisabledModes>
              <NAT localhost-reachable="true"/>
              <InternalNetwork name="intnet"/>
              <NATNetwork name="NatNetwork"/>
            </DisabledModes>
            <BridgedInterface name="pentap0"/>
          </Adapter>
        </Network>
        <AudioAdapter useDefault="true" driver="ALSA" enabled="true"/>
        <Clipboard mode="${vbox_clipboard_mode}"/>
        <StorageControllers>
          <StorageController name="SATA" type="AHCI" PortCount="30" useHostIOCache="false" Bootable="true" IDE0MasterEmulationPort="0" IDE0SlaveEmulationPort="1" IDE1MasterEmulationPort="2" IDE1SlaveEmulationPort="3">
            <AttachedDevice type="HardDisk" hotpluggable="false" port="0" device="0">
              <Image uuid="{f4582d13-07af-4392-bc84-2abfcc0eee81}"/>
            </AttachedDevice>
          </StorageController>
        </StorageControllers>
        <RTC localOrUTC="UTC"/>
        <CPU count="${vm_cpu_core}">
          <HardwareVirtExLargePages enabled="false"/>
          <PAE enabled="false"/>
          <LongMode enabled="true"/>
          <X2APIC enabled="true"/>
        </CPU>
      </Hardware>
    </vbox:Machine>
  </VirtualSystem>
</Envelope>
