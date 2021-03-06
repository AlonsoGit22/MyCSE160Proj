/*
 * ANDES Lab - University of California, Merced
 * This class provides the basic functions of a network node.
 *
 * @author UCM ANDES Lab
 * @date   2013/09/03
 *
 */
#include <Timer.h>
#include "includes/command.h"
#include "includes/packet.h"
#include "includes/CommandMsg.h"
#include "includes/sendInfo.h"
#include "includes/channels.h"


module Node{
   uses interface Boot;

   uses interface SplitControl as AMControl;
   uses interface Receive;

   uses interface SimpleSend as Sender;

   uses interface CommandHandler;

    /*include all the processes from the lab proj 1 slide */
uses interface NeighborQueueListC<uint16_t> as NeighborQueueList;
uses interface PoolC<uint16_t> as NeighborPool;
uses interface TimerMilliC as NodeTimer;
uses interface RandomC as Random;
}

implementation{
   pack sendPackage;
uint16_t sequenceCount = 1;
unit16_t sequence = 0;
uint16_t replysequence = 0;
/* M make sequence counter */


   // Prototypes
   void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t Protocol, uint16_t seq, uint8_t *payload, uint8_t length);

   event void Boot.booted(){
      call AMControl.start();

      dbg(GENERAL_CHANNEL, "Booted\n");
   }

   event void AMControl.startDone(error_t err){
      if(err == SUCCESS){
         dbg(GENERAL_CHANNEL, "Radio On\n");
      }else{
         //Retry until successful
         call AMControl.start();
      }
   }

   event void AMControl.stopDone(error_t err){}

   event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
      dbg(GENERAL_CHANNEL, "Packet Received\n");
      if(len==sizeof(pack)){
         pack* myMsg=(pack*) payload;
if(TOS_NODE_ID == myMsg -> dest){
//check if protocol is ping if true
if (PROTOCOL_PING == TRUE) {
makePack(&sendPackage, myMsg->dest, myMsg->src, 0, 0, 1, payload, PACKET_MAX_PAYLOAD_SIZE);
call Sender.send(sendPackage, AM_BROADCAST_ADDR);
}
// make pack (src->dest,dest->src, 1)
dbg(GENERAL_CHANNEL, "Package Payload: %s\n", myMsg->payload);
return msg;
}else{
makePack(&sendPackage, myMsg->src, myMsg->dest, 0, 0, 0, payload, PACKET_MAX_PAYLOAD_SIZE);
call Sender.send(sendPackage, AM_BROADCAST_ADDR);
}

      }
      dbg(GENERAL_CHANNEL, "Unknown Packet Type %d\n", len);
      return msg;
   }




   event void CommandHandler.ping(uint16_t destination, uint8_t *payload){
      dbg(GENERAL_CHANNEL, "PING EVENT \n");
      makePack(&sendPackage, TOS_NODE_ID, destination, 0, 0, 0, payload, PACKET_MAX_PAYLOAD_SIZE);
      call Sender.send(sendPackage, AM_BROADCAST_ADDR);
   }

   event void CommandHandler.printNeighbors(){}

   event void CommandHandler.printRouteTable(){}

   event void CommandHandler.printLinkState(){}

   event void CommandHandler.printDistanceVector(){}

   event void CommandHandler.setTestServer(){}

   event void CommandHandler.setTestClient(){}

   event void CommandHandler.setAppServer(){}

   event void CommandHandler.setAppClient(){}

   void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length){
      Package->src = src;
      Package->dest = dest;
      Package->TTL = TTL;
      Package->seq = seq;
      Package->protocol = protocol;
      memcpy(Package->payload, payload, length);
   }
}
